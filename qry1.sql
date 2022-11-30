SELECT jdict('documentId', docid, 'projectId', id, 'confidenceLevel', 0.8, 'textsnippet', (prev||" <<< "||middle||" >>> "||NEXT)) AS C1, docid, id, fundingclass1, grantid
FROM
  (SELECT docid, id, fundingclass1, grantid, prev, middle,NEXT
   FROM
     (SELECT *
      FROM
        (setschema 'docid,prev,middle,next' SELECT c1 AS docid,
            textwindow2s(regexpr("\n", c2, " "), 10, 1, 10, '(?:RBSI\d{2}\w{4})|(?:2015\w{6})')
         FROM
           (setschema 'c1,c2' SELECT *
            FROM pubs
            WHERE c2 IS NOT NULL)), grants
      WHERE fundingclass1="MIUR"
        AND regexpr("((?:RBSI\d{2}\w{4})|(?:2015\w{6}))", middle) = grantid)
   GROUP BY docid, id)
UNION ALL
SELECT jdict('documentId', docid, 'projectId', id, 'confidenceLevel', sqroot(min(1.49, confidence)/1.5), 'textsnippet', (prev||" <<< "||middle||" >>> "||NEXT)) AS C1, docid, id, fundingclass1, grantid
FROM
  (SELECT prev, middle, NEXT, docid, id, max(confidence) AS confidence, docid, id, fundingclass1, grantid
   FROM
     (SELECT (0.3 +hardmatch*0.6 +subrcukmatch +rcukmatch) AS confidence, docid, id, prev, middle, NEXT, fundingclass1, grantid
      FROM
        (unindexed SELECT regexprmatches('\bRCUK\b|\bUKRI\b|[Rr]esearch [Cc]ouncils UK', context) AS rcukmatch,
                          regexprmatches('\b'||rcuk_subfunder||'\b', context) AS subrcukmatch,
                          regexprmatches('(?:G\d{6,7})|(?:[A-Z]{2}\/\w{6,7}\/\d{1,2}(?:\/xx)?)|(?:(?:BBS|PPA)\/[A-Z](?:\/[A-Z])?\/(?:\w{8,9}|(?:\d{4}\/)?\d{5}(?:\/\d)?))|(?:(?:RES|PTA)-\d{3}-\d{2}-\d{4}(?:-[A-Z]|-\d{1,2})?)|(?:MC_(?:\w{8,10}|\w{2}_(?:\w{2,4}_)?(?:\d{4,5}|[UG]\d{7,9})(?:\/\d{1,2})?))|(?:MC_\w{2}_\w{2}(?:_\w{2})?\/\w{7}(?:\/\d)?)|(?:ESPA-[A-Z]{3,6}-\d{4}(?:-[A-Z]{3}-\d{3}|-\d{3})?)', middle) AS hardmatch,
                          docid, id, fundingclass1, grantid, middle, prev, NEXT
         FROM
           (SELECT docid,
                   stripchars(middle, '.)(,[]') AS middle,
                   prev,
                   NEXT,
                   prev||' '||middle||' '||NEXT AS context
            FROM
              (setschema 'docid,prev,middle,next' 
                SELECT c1, textwindow2s(c2, 15, 1, 1, '(?:[SG]?\d{5,7}(?:\/\d)?)|(?:[A-Z]{2}\/\w{6,7}\/\d{1,2}(?:\/xx)?)|(?:[GE]\d{2,3}\/\d{1,4})|(?:(?:BBS|PPA)\/[A-Z](?:\/[A-Z])?\/(?:\w{8,9}|(?:\d{4}\/)?\d{5}(?:\/\d)?))|(?:(?:RES|PTA)-\d{3}-\d{2}-\d{4}(?:-[A-Z]|-\d{1,2})?)|(?:MC_(?:\w{8,10}|\w{2}_(?:\w{2,4}_)?(?:\d{4,5}|[UG]\d{7,9})(?:\/\d{1,2})?))|(?:MC_\w{2}_\w{2}(?:_\w{2})?\/\w{7}(?:\/\d)?)|(?:[A-Za-z]{3,9}\d{5,7}a?)|(?:ESPA-[A-Z]{3,6}-\d{4}(?:-[A-Z]{3}-\d{3}|-\d{3})?)')
               FROM pubs
               WHERE c2 IS NOT NULL )), grants
         WHERE fundingclass1="UKRI" AND middle = grantid )
      WHERE confidence>0.3 )
   GROUP BY docid, id)
UNION ALL 
SELECT jdict('documentId', docid, 'projectId', id, 'confidenceLevel', 0.8, 'textsnippet', (prev||" <<< "||middle||" >>> "||NEXT)) AS C1, docid, id, fundingclass1, grantid
FROM
  (setschema 'docid,prev,middle,next' 
      SELECT c1, textwindow2s(filterstopwords(keywords(c2)), 10, 2, 7, "\w{3}\s\d{1,4}")
   FROM pubs
   WHERE c2 IS NOT NULL), grants
WHERE lower(regexpr("\b(\w{3}\s\d{1,4})\b", middle)) = grantid
  AND regexprmatches("support|project|grant|fund|thanks|agreement|research|acknowledge|centre|center|nstitution|program|priority|dfg|german|dutch|deutche", lower(prev||" "||NEXT))
GROUP BY docid, id 

UNION ALL 

SELECT jdict('documentId', docid, 'projectId', id, 'confidenceLevel', 0.8, 'textsnippet', textsnippet) AS C1,
        docid, id, fundingclass1, grantid
FROM
  (SELECT docid,
          CASE
              WHEN regexprmatches(".*(?:(?:CIHR|IRSC)|(?i)(?:canad(?:ian|a) institute(?:s)? health research|institut(?:(?:e)?(?:s)?)? recherche sant(?:é|e) canada)).*", prev||" "||middle||" "||NEXT) THEN
                     (SELECT id
                      FROM grants
                      WHERE fundingclass1 = 'CIHR')
              WHEN regexprmatches(".*(?:(?:NSERC|CRSNG)|(?i)(?:nat(?:ural|ional) science(?:s)?(?:\sengineering(?:\sresearch)?|\sresearch) co(?:u)?n(?:c|se)(?:i)?l|conseil(?:s)? recherche(?:s)? science(?:s)? naturel(?:les)?(?:\sg(?:e|é)nie)? canada)).*", prev||" "||middle||" "||NEXT) THEN
                     (SELECT id
                      FROM grants
                      WHERE fundingclass1 = 'NSERC')
              WHEN regexprmatches(".*(?:(?:SSHRC|CRSH|SSRCC)|(?i)(?:social science(?:s)?|conseil(?:s)? recherche(?:s)?(?:\ssciences humaines)? canada|humanities\sresearch)).*", prev||" "||middle||" "||NEXT) THEN
                     (SELECT id
                      FROM grants
                      WHERE fundingclass1 = 'SSHRC')
              ELSE 'canadian_unspecified_id'
          END AS id,
          "unidentified" AS grantid,
          "Canadian" AS fundingclass1,
          (prev||" <<< "||middle||" >>> "||NEXT) AS textsnippet
   FROM
     (setschema 'docid,prev,middle,next' SELECT c1, textwindow2s(filterstopwords(keywords(c2)), 15, 1, 15, "^(?:(?:(?:CIHR|IRSC)|(?:NSERC|CRSNG)|(?:SSHRC|CRSH))|(?i)(?:co(?:(?:un(?:cil|sel))|(?:nseil(?:s)?))|canad(?:a|ian)))$")
      FROM pubs
      WHERE c2 IS NOT NULL)
   WHERE (/* Terms */ /* Acronyms */ regexprmatches("^(?:CIHR|(?:NSERC|CRSNG)|(?:SSHRC|CRSH|SSRCC))$", middle)
          OR (regexprmatches("^IRSC$", middle) /* This is the french acronym of CIHR. It also refers to some other organizations, so we search and exclude them. */
              AND NOT regexprmatches(".*(?:informal relationships social capital|interlocus sexual conflict|international (?:rosaceae|rosbreed) snp consortium|iranian seismological cent(?:er|re)).*", lower(prev||" "||NEXT)))
          OR (/* Full-names */ (/* Middle: "Council", "Counsel", "Conseil", "Conseils" --> NSERC/CRSNG, SSHRC/CRSH/SSRCC */ regexprmatches("^co(?:(?:un(?:cil|sel))|(?:nseil(?:s)?))$", lower(middle))
                                AND ( 
 (regexprmatches("^recherche(?:s)?(?:(?:\s(?:g(?:e|é)nie|science(?:s)?)(?:\s(?:humaines|naturel(?:les)?)?)?(?:\sg(?:e|é)nie)?)?)?\scanada.*", lower(NEXT)) 
  OR regexprmatches("^social\sscience(?:s)?\shumanities\sresearch\scanada.*", lower(NEXT)) 
 ) 
                                     OR 
 ((regexprmatches(".*(?:social|nat(?:ural|ional))\sscience(?:s)?\s(?:(?:engineering|humanities)(?:\sresearch)?|research)$", lower(prev)) 
   OR regexprmatches(".*humanities\sresearch$", lower(prev))) 
  AND (
 regexprmatches("^canada.*", lower(NEXT))
       OR regexprmatches(".*canada\s(?:social|nat(?:ural|ional)).*", lower(prev))))))
              OR (/* Middle: "Canada", "Canadian" --> CIHR/IRSC */ regexprmatches("^canad(?:a|ian)$", lower(middle)) 
                  AND (
 regexprmatches("^institute(?:s)?\shealth\sresearch.*", lower(NEXT))
                       OR 
 regexprmatches(".*institut(?:(?:e)?(?:s)?)?\srecherche\ssant(?:e|é)$", lower(prev))))))
     AND (/* Relation */ regexprmatches(".*(?:fund|support|financ|proje(?:c)?t|grant|subvention|sponsor|parrain|souten|subsidiz|promot|acquir|acknowledg|administ|assist|donor|bailleur|g(?:e|é)n(?:e|é)rosit).*", lower(prev||" "||NEXT))
          OR regexprmatches(".*(?:thank|gratefull|(?:re)?merci).*", lower(prev))) )
WHERE id IS NOT NULL
GROUP BY docid,
         id
UNION ALL
SELECT jdict('documentId', docid, 'projectId', id, 'confidenceLevel', 0.8, 'textsnippet', (prev||" <<< "||middle||" >>> "||NEXT)) AS C1, docid, id, fundingclass1, grantid
FROM
  (SELECT docid, id, fundingclass1, grantid, prev, middle, NEXT
   FROM
     (SELECT docid, id, grantid, middle, fundingclass1, grantid, prev, middle, NEXT
      FROM
        (setschema 'docid,prev,middle,next' SELECT c1 AS docid, textwindow2s(c2, 15, 1, 5, "(?:\bANR-\d{2}-\w{4}-\d{4}\b)|\b(?:06|07|10|11|12|13|14|15|16|17|18|19)\-\w{4}\-\d{4}(?:\-\d{2})*\b|(.+\/\w+\/\d{4}\W*\Z)|(\d{4})|(\d{2}-\d{2}-\d{5})|(\d{6,7})|(\w{2}\d{4,})|(\w+\/\w+\/\w+)|(\w*\/[\w,\.]*\/\w*)|(?:\d{3}\-\d{7}\-\d{4})|(?:(?:\b|U)IP\-2013\-11\-\d{4}\b)|(\b(?:(?:(?:\w{2,3})(?:\.|\-)(?:\w{2,3})(?:\.|\-)(?:\w{2,3}))|(?:\d+))\b)|(?:\b\d{7,8}\b)|(?:\b\d{3}[A-Z]\d{3}\b)|(?:[A-Z]{2,3}.+)|(?:\d{4}\-\w+\-\w+(\-\d+)*)|(?:\d{4}\-\d{2,})")
         FROM
           (setschema 'c1,c2' SELECT *
            FROM pubs
            WHERE c2 IS NOT NULL)) , grants
      WHERE (regexpr("((?:[\w,\.\-]*\/)+\d+)", middle) = grantid
             AND (fundingclass1 in ("FCT", "ARC")))
        OR (regexpr("(\d{5,7})", middle)=grantid
            AND fundingclass1 = "NHMRC"
            AND regexprmatches("nhmrc|medical research|national health medical", filterstopwords(normalizetext(lower(j2s(prev, middle, NEXT))))))
        OR (regexpr("(\w*\/[\w,\.]*\/\w*)", middle)=grantid
            AND fundingclass1 = "SFI")
        OR (regexpr("\b((?:06|07|10|11|12|13|14|15|16|17|18|19)\-\w{4}\-\d{4}(?:\-\d{2})*)\b", middle)=grantid
            AND fundingclass1 = "ANR")
        OR (regexpr("\b(ANR-\d{2}-\w{4}-\d{4})\b", middle)=grantid
            AND fundingclass1 = "ANR")
        OR (regexpr("(\d+)", middle)=grantid
            AND fundingclass1 = "CONICYT"
            AND regexprmatches("conicyt|fondecyt", lower(j2s(prev, middle, NEXT))))
        OR (regexpr("(\b\d{3}[A-Z]\d{3}\b)", middle)=grantid
            AND fundingclass1 = "TUBITAK"
            AND regexprmatches("tubitak|tubitek|tbag|turkey|turkish|\btub\b|\bbitak\b|\bitak\b|tub|ubitak|tu bi tak|tubtak|itak|project", lower(j2s(prev, middle, NEXT))))
        OR (stripchars(regexpr("([A-Z]{2,3}.+)", middle), "[]\().{}?;") = grantid
            AND fundingclass1 = "SGOV")
        OR (regexpr("(\d{4}\-\w+\-\w+(?:\-\d+)*)", middle) = grantid
            AND fundingclass1="INNOVIRIS")
        OR (regexpr("(\d{4}\-\d+)", regexpr("\-ANTICIPATE\-|\-ATTRACT\-|\-PRFB\-|\-BB2B\-", middle, "-")) = grantid
            AND fundingclass1="INNOVIRIS"
            AND (regexprmatches("innoviris|prfb", lower(j2s(prev, middle, NEXT)))
                 OR regexprmatches("anticipate$|attract$", lower(prev)))
            AND regexprmatches("\banticipate\b|\battract\b|prfb|\bbb2b\b", lower(j2s(prev, middle, NEXT))))
        OR (regexpr("(\d{2}-\d{2}-\d{5})", middle) = grantid
            AND fundingclass1 = "RSF"
            AND ((regexpcountwithpositions("(?:russian science foundation)|(?:russian science fund)|(?:russian scienti)|(?:russian scientific foundation)|(?:russian scientific fund)|(?:scientific foundation of russian federation)|(?:rsf)|(?:rusiina scientific foundation)|(?:russ. sci. found.)|(?:russan science foundation)|(?:russia science foundation)|(?:russian academic fund)|(?:russian federation)|(?:russian federation foundation)|(?:russian foundation for sciences)|(?:russian foundation of sciences)|(?:russian fundamental research foundation)|(?:russian research foundation)|(?:russian scence foundation)|(?:russian sci. fou.)|(?:russian science)|(?:rnf)|(?:russian national foundation)|(?:rnsf)|(?:russian national science foundation)|(?:rscf)|(?:rscif)|(?:rsp)|(?:rcf)", lower(prev)) + regexpcountwithpositions("(?:russian science foundation)|(?:russian science fund)|(?:russian scienti)|(?:russian scientific foundation)|(?:russian scientific fund)|(?:scientific foundation of russian federation)|(?:rsf)|(?:rusiina scientific foundation)|(?:russ. sci. found.)|(?:russan science foundation)|(?:russia science foundation)|(?:russian academic fund)|(?:russian federation)|(?:russian federation foundation)|(?:russian foundation for sciences)|(?:russian foundation of sciences)|(?:russian fundamental research foundation)|(?:russian research foundation)|(?:russian scence foundation)|(?:russian sci. fou.)|(?:russian science)|(?:rnf)|(?:russian national foundation)|(?:rnsf)|(?:russian national science foundation)|(?:rscf)|(?:rscif)|(?:rsp)|(?:rcf)", lower(NEXT), 1)) - (regexpcountwithpositions("RFBR|Basic|BASIC", NEXT, 1) + regexpcountwithpositions("RFBR|Basic|BASIC", prev)) >= 0))
        OR (regexpr("(\w+\/\w+\/\w+)", middle) = grantid
            AND fundingclass1="RPF"
            AND regexprmatches("cyprus|rpf", lower(j2s(prev, middle, NEXT))))
        OR (regexpr("(\d{3}\-\d{7}\-\d{4})", middle) = grantid
            AND fundingclass1="MZOS"
            AND regexprmatches("croatia|\bmses\b|\bmzos\b|ministry of science", lower(j2s(prev, middle, NEXT))))
        OR (regexpr("(\d{4})", middle) = grantid
            AND fundingclass1="HRZZ"
            AND (regexprmatches(normalizedacro, j2s(prev, middle, NEXT))
                 OR regexprmatches("croatian science foundation|\bhrzz\b", lower(j2s(prev, middle, NEXT)))))
        OR (fundingclass1="NWO"
            AND regexpr("(\b(?:(?:(?:\w{2,3})(?:\.|\-)(?:\w{2,3})(?:\.|\-)(?:\w{2,3}))|(?:\d+))\b)", middle)=nwo_opt1
            AND regexprmatches("\bvici\b|\bvidi\b|\bveni\b|\bnwo\b|dutch|netherlands|\b"||lower(nwo_opt2)||"\b", lower(j2s(prev, middle, NEXT))))
        OR (fundingclass1="SNSF"
            AND regexpr('0{0,1}(\d{5,6})', middle)=grantid
            AND regexprmatches('(?:\bsnsf\b)|(?:swiss national (?:science)?\s?foundation\b)', lower(j2s(prev, middle, NEXT))))
      GROUP BY docid,
               id))
UNION ALL
SELECT jdict('documentId', docid, 'projectId', id, 'confidenceLevel', 0.8, 'textsnippet', (prev||" <<< "||middle||" >>> "||NEXT)) AS C1, docid, id, fundingclass1, grantid
FROM
  (SELECT docid, id, fundingclass1, grantid, prev, middle, NEXT
   FROM
     (SELECT *
      FROM
        (setschema 'docid,prev,middle,next' SELECT c1 AS docid, textwindow2s(regexpr("\n", c2, " "), 7, 2, 3, "\w{1,3}\s*\d{1,5}(?:(?:\-\w\d{2})|\b)")
         FROM
           (setschema 'c1,c2' SELECT *
            FROM pubs
            WHERE c2 IS NOT NULL)) ,grants
      WHERE fundingclass1="FWF"
        AND regexpr("(\w{1,3}\s*\d{1,5})", middle) = grantid
        AND (regexprmatches("austrian|fwf", lower(j2s(prev, middle, NEXT)))
             OR regexprmatches(ALIAS, j2s(prev, middle, NEXT))))
   GROUP BY docid, id)
UNION ALL
SELECT jdict('documentId', docid, 'projectId', id, 'confidenceLevel', sqroot(min(1.49, confidence)/1.5), 'textsnippet', (prev||" <<< "||middle||" >>> "||NEXT)) AS C1, docid, id, fundingclass1, grantid
FROM
  (SELECT prev, middle, NEXT, docid, id, max(confidence) AS confidence, small_string, string, fundingclass1, grantid
   FROM
     (SELECT docid, id,
             (fullprojectmatch*10 +coreprojectmatch*10 +(activitymatch>0)*(administmatch>0)*length(nih_serialnumber)*2.5 +(activitymatch>0)*length(nih_serialnumber)*0.666 +(administmatch>0)*length(nih_serialnumber)*1 +orgnamematch+nihposshortmatch*2+nihposfullmatch*5 +nihpositivematch-nihnegativematch)*0.0571 AS confidence,
             nih_serialnumber,
             small_string, string, fundingclass1,
                                   grantid,
                                   string AS prev,
                                   "" AS middle,
                                   "" AS NEXT
      FROM
        (unindexed SELECT regexpcountuniquematches('(?:[\W\d])'||nih_activity||'(?=[\W\w])(?!/)', small_string) AS activitymatch,
                          regexpcountuniquematches('(?:[\WA-KIR\d])'||nih_administeringic||'(?=[\W\d])(?!/)', small_string) AS administmatch,
                          regexpcountwords('\b(?i)'||keywords(nih_orgname)||'\b', keywords(string)) AS orgnamematch,
                          regexprmatches(grantid, small_string) AS fullprojectmatch,
                          regexprmatches(nih_coreprojectnum, small_string) AS coreprojectmatch,
                          regexpcountuniquematches(var('nihposshort'), string) AS nihposshortmatch,
                          regexpcountuniquematches(var('nihposfull'), string) AS nihposfullmatch,
                          regexpcountuniquematches(var('nihpositives'), string) AS nihpositivematch,
                          regexpcountuniquematches(var('nihnegatives'), string) AS nihnegativematch,
                          docid,
                          id,
                          nih_serialnumber,
                          length(nih_serialnumber) AS serialnumberlength,
                          small_string, string, fundingclass1,
                                                grantid
         FROM
           (SELECT docid,
                   middle,
                   j2s(prev1, prev2, prev3, prev4, prev5, prev6, prev7, prev8, prev9, prev10, middle, next1, next2, next3, next4, next5) AS string,
                   j2s(prev9, prev10, middle) AS small_string
            FROM
              (setschema 'docid, prev1, prev2, prev3, prev4, prev5, prev6, prev7, prev8, prev9, prev10, middle, next1, next2, next3, next4, next5' SELECT c1 AS docid, textwindow(regexpr('\n', c2, ''), 10, 5, 1, '\d{4,7}\b')
               FROM pubs
               WHERE c2 IS NOT NULL )), grants
         WHERE fundingclass1='NIH'
           AND regexpr('^0+(?!\.)', regexpr('(\d{3,})', middle), '') = nih_serialnumber
           AND (activitymatch
                OR administmatch) )
      WHERE confidence > 0.5)
   GROUP BY docid,
            nih_serialnumber)
UNION ALL
SELECT jdict('documentId', docid, 'projectId', id, 'confidenceLevel', sqroot(min(1.49, confidence)/1.5), 'textsnippet', (prev||" <<< "||middle||" >>> "||NEXT)) AS C1, docid, id, fundingClass1, grantid
FROM
  (SELECT prev, middle, NEXT, docid, id, max(confidence) AS confidence, fundingClass1, grantid
   FROM
     (SELECT docid, id, fundingClass1, grantid, prevpack AS prev, middle, nextpack AS NEXT,
             CASE
                 WHEN fundingClass1="WT" THEN /*wellcome trust confidence*/ (regexpcountwords(var('wtpospos'), j2s(prevpack, nextpack)) * regexpcountwords('(?:collaborative|joint call)', j2s(prevpack, nextpack)))*0.33 + regexprmatches('\d{5}ma(?:\b|_)', middle)+ regexprmatches('(?:\d{5}_)(?:z|c|b|a)(?:_\d{2}_)(?:z|c|b|a)', middle)*2+ regexpcountwords(var('wtpospos'), prev)*0.5+ regexprmatches(var('wtpospos'), middle)+ regexpcountwithpositions(var('wtpospos'), prevpack)*0.39 + 0.21*regexpcountwithpositions(var('wtpospos'), nextpack, 1) - (regexprmatches(var('wtnegheavy'), middle) + regexprmatches('(?:n01|r01|dms)', middle) +regexprmatches('(?:ns|mh|hl|hd|ai)(?:_|)\d{5}', middle))*10 - 4*regexpcountwords('(?:a|g|c|t|u){4}', middle) - regexprmatches(var('wtneglight'), middle)*0.3 - regexpcountwithpositions(var('wtnegheavy'), prevpacksmall, 0, 1, 0.5)*0.39 - regexpcountwithpositions(var('wtneglight'), prevpacksmall, 0, 1, 0.5)*0.18 - 0.45*regexpcountwithpositions(var('wtneglight'), nextpack) - 0.21*regexpcountwithpositions(var('wtnegheavy'), nextpack, 1)
                 WHEN fundingClass1="NSF" THEN regexpcountwords("\bnsf\b|national science foundation", j2s(prevpack, middle, nextpack)) - 5 * regexpcountwords("china|shanghai|danish|nsfc|\bsnf\b|bulgarian|\bbnsf\b|norwegian|rustaveli|israel|\biran\b|shota|georgia|functionalization|manufacturing", j2s(prevpack, middle, nextpack))
                 WHEN fundingClass1="MESTD" THEN regexpcountwords("serbia|mestd", j2s(prevpacksmall, middle, nextpack))
                 WHEN fundingClass1="GSRI" THEN regexpcountwords("gsrt|\bgsri\b", j2s(prevpacksmall, middle, nextpack))
                 WHEN fundingClass1="EC"/* fp7 confidence */ THEN 
                   CASE
                      WHEN fundingClass2 = "FP7" THEN regexprmatches(var('fp7middlepos'), middle)+ regexprmatches('(?:\b|_|\d)'||normalizedacro||'(?:\b|_|\d)', j2s(middle, prevpacksmall, nextpack))*2 + regexprmatches('fp7', prev15)*0.4 + 0.4*regexpcountwithpositions(var('fp7pospos'), prevpacksmall) + 0.16*regexpcountwords(var('fp7pos'), prevpacksmall) + 0.1*regexpcountwithpositions(var('fp7pospos'), nextpack, 1) + regexpcountwords(var('fp7pos'), nextpack)*0.04 - regexprmatches(var('fp7negheavy'), middle)*1 - 0.4*regexpcountwords('(a|g|c|t|u){4}', middle) - regexprmatches(var('fp7neglight'), middle)*0.3 - regexpcountwithpositions(var('fp7negheavy'), prevpacksmall)*0.48 - regexpcountwithpositions(var('fp7neglight'), prevpacksmall)*0.18 - (((regexpcountwords(('\b_*\d+_*\b'),prevpacksmall)+ (regexpcountwords(('\b_*\d+_*\b'),nextpack)))/4))*0.2 - regexpcountwithpositions(var('fp7neglight'), nextpack)*0.03 - regexpcountwithpositions(var('fp7negheavy'), nextpack, 1)*0.08
                      WHEN fundingClass2="H2020" THEN 2*regexprmatches(normalizedacro, prevpack||" "||middle||" "||nextpack) + regexpcountwords("h2020|horizon\s*2020|european\s*research\s*council|\berc\b|sk\wodowska|curie grant|marie\s*sklodowska\s*curie|marie\s*curie|european\s*commission|\beu\s*grant|\beu\s*project|\bec\s*grant|\bec\s*project|european\s*union", j2s(prevpack, middle, nextpack))
                END
             END AS confidence
      FROM
        (SELECT id, fundingClass1, fundingClass2, docid, normalizedacro, 
                j2s(prev14, prev15) AS prev, grantid, prev15,
                j2s(prev1, prev2, prev3, prev4, prev5, prev6, prev7, prev8, prev9, prev10, prev11, prev12, prev13, prev14, prev15) AS prevpack,
                j2s(prev9, prev10, prev11, prev12, prev13, prev14, prev15) AS prevpacksmall,
                middle,
                j2s(next1, next2, next3) AS nextpack
         FROM
           (SELECT *
            FROM
              (setschema 'docid,prev1, prev2, prev3, prev4, prev5, prev6, prev7, prev8, prev9, prev10, prev11, prev12, prev13, prev14, prev15, middle, next1, next2, next3' SELECT c1 AS docid,
              textwindow(regexpr('(\b\S*?[^0-9\s_]\S*?\s_?)(\d{3})(\s)(\d{3})(_?\s\S*?[^0-9\s_]\S*?\b)', filterstopwords(normalizetext(lower(c2))), '\1\2\4\5'), 15, 3, '((?:(?:\b|\D)0|_|\b|\D)(?:\d{5}))|(((\D|\b)\d{6}(\D|\b)))|(?:(?:\D|\b)(?:\d{7})(?:\D|\b)) ')
               FROM
                 (setschema 'c1,c2' SELECT *
                  FROM pubs
                  WHERE c2 IS NOT NULL)) ,grants
            WHERE (NOT regexprmatches('(?:0|\D|\b)+(?:\d{8,})', middle)
                   AND NOT regexprmatches('(?:\D|\b)(?:\d{7})(?:\D|\b)', middle)
                   AND regexpr('(?:0|\D|\b)+(\d{5})', middle) = grantid
                   AND fundingclass1 in ('WT','EC'))
              OR ((NOT regexprmatches('(\d{6,}(?:\d|i\d{3}_?\b))|(jana\d{6,})', middle))
                  AND NOT regexprmatches('(?:\D|\b)(?:\d{7})(?:\D|\b)', middle)
                  AND regexpr('(\d{6})', middle) = grantid
                  AND fundingclass1 in ('WT', 'EC'))
              OR (regexprmatches('(?:(?:\D|\b)(?:\d{7})(?:\D|\b))', middle)
                  AND regexpr("(\d{7})", middle) = grantid
                  AND fundingclass1='NSF')
              OR (regexpr("(\d{5,6})", middle) = grantid
                  AND fundingclass1='MESTD')
              OR (regexpr("(\d{6})", middle) = grantid
                  AND fundingclass1='GSRI') ))
      WHERE confidence > 0.16)
   GROUP BY docid, id);

   