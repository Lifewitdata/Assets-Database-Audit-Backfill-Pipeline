WITH coverage AS (
 SELECT neighborhood, building_class, COUNT(*) AS records,
 SUM(CASE WHEN address IS NOT NULL AND TRIM(address)<>'' THEN 1 ELSE 0 END) AS address_present,
 SUM(CASE WHEN sale_price IS NOT NULL THEN 1 ELSE 0 END) AS price_present,
 SUM(CASE WHEN gross_square_feet IS NOT NULL THEN 1 ELSE 0 END) AS area_present,
 SUM(CASE WHEN residential_units IS NOT NULL THEN 1 ELSE 0 END) AS units_present,
 SUM(CASE WHEN sale_price>0 AND gross_square_feet>0 THEN 1 ELSE 0 END) AS positive_price_area
 FROM records GROUP BY neighborhood,building_class
)
SELECT *,ROUND(100.0*(address_present+price_present+area_present+units_present)/(4*records),2)
 AS field_completeness_pct FROM coverage ORDER BY field_completeness_pct,records DESC;
