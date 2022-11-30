select jdict('documentId', docid, 'projectId', id, 'confidenceLevel', 
       sqroot(min(1.49,confidence)/1.5), 'textsnippet', context) as C1, 
       docid, id, fundingclass1, grantid, context from ( 
          select docid,id,confidence, docid, id,  fundingclass1, grantid, context from ( 
            select 0.8 as confidence, docid, id, fundingclass1, grantid, context from (
               unindexed 
               select docid, regexpr("(\d+)",middle) as middle, 
               comprspaces(j2s(prev1,prev2,prev3,prev4,prev5,prev6,prev7,prev8,prev9,prev10,prev11,prev12,prev13,"<<<",middle,">>>",next)) as context
               from (
                setschema 'docid,prev1,prev2,prev3,prev4,prev5,prev6,prev7,prev8,prev9,prev10,prev11,prev12,prev13,middle,next' select c1, textwindow(lower(c2),-13,0,1, '\b\d{5,6}\b') 
                from pubs where c2 is not null
               ) 
            where CAST(regexpr("(\d+)",middle) AS INT)>70000), grants
          WHERE fundingclass1="AKA" and 
                (regexprmatches("[\b\s]academy of finland[\b\s]", context) or 
                  regexprmatches("[\b\s]finnish (?:(?:programme for )?cent(?:re|er)s? of excellence|national research council|funding agency|research program)[\b\s]", context) 
                  or regexprmatches("[\b\s]finnish academy[\b\s]", context)) 
                and grantid=middle
) group by docid,id);

