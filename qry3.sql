-- Zillow query
--
-- Our original, full query includes count(distinct xx). 
-- In our experiments, we saw that 'unique' does not work 
-- in tuplex (at least at the time we ran the experiments). 
-- So for compatibility across all systems tested, we also 
-- tested the query with simple count(xx) (as shown here)
-- 
-- Used in the experiments of figures 2, 5, and 7
--


SELECT SUM(bathrooms) AS sum_ba, 
       SUM(sqft) AS sum_sqft, 
       COUNT(url) AS urls, 
       COUNT(offer) AS offers, 
       COUNT(zip_code) AS zip_codes
FROM 
    (
        SELECT t.bedrooms, 
               extract_ba(t.facts_and_features) AS bathrooms, 
               extract_sqft(t.facts_and_features) AS sqft,
               extract_pcode(t.postal_code) AS zip_code, 
               replace_o_a(strip(to_lower(t.url))) AS url, 
               extract_offer(t.title) AS offer
        FROM (
            SELECT extract_bd(facts_and_features) AS bedrooms, 
                   extract_price(price) AS price_n, * 
            FROM zillow_large
        ) AS t
        WHERE t.bedrooms < 10 AND t.price_n > 100000 AND t.price_n < 20000000
    ) AS t
GROUP BY t.bedrooms;

