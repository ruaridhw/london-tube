CREATE VIEW inbound_graph AS (

WITH LINE_ABBR AS (

	SELECT *, SUBSTRING("RouteLink" from 6 for 3) Line -- Create tube line code
	FROM "RouteLinks"
	WHERE "Direction" = 'inbound' -- Get inbound routes only

)--, STOPS AS (

SELECT
	 "line"
	,f."CommonName" From_CommonName
	,t."CommonName" To_CommonName
	,f."Longitude" From_Longitude
	,f."Latitude" From_Latitude
	,t."Longitude" To_Longitude
	,t."Latitude" To_Latitude
FROM LINE_ABBR

LEFT JOIN "StopPoints" f
ON "From_StopPointRef" = f."AtcoCode"

LEFT JOIN "StopPoints" t
ON "To_StopPointRef" = t."AtcoCode"

GROUP BY
	 "line"
	,f."CommonName"
	,t."CommonName"
	,f."Longitude"
	,f."Latitude"
	,t."Longitude"
	,t."Latitude"

)

--)

-- SELECT line, COUNT(*)
-- FROM STOPS
-- GROUP BY line
