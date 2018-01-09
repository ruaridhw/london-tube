/*
---
title: "Inbound Graph"
author: "Ruaridh Williamson"
---

PostgreSQL view of all the distinct RouteLinks by Line
with additional info such as StopPoint Latitude and Longitude
*/

CREATE OR REPLACE VIEW inbound_graph AS

WITH LINE_ABBR AS (

	SELECT *, SUBSTRING("RouteLink" from 6 for 3) "Line" -- Create tube line code
	FROM "RouteLinks"
	WHERE "Direction" = 'inbound' -- Get inbound routes only

)

SELECT
	 "Line"
	,f."CommonName" "From_StopPointName"
	,t."CommonName" "To_StopPointName"
	,f."Longitude" "From_Longitude"
	,f."Latitude" "From_Latitude"
	,t."Longitude" "To_Longitude"
	,t."Latitude" "To_Latitude"
FROM LINE_ABBR

LEFT JOIN "StopPoints" f
ON "From_StopPointRef" = f."AtcoCode"

LEFT JOIN "StopPoints" t
ON "To_StopPointRef" = t."AtcoCode"

GROUP BY
	 "Line"
	,f."CommonName"
	,t."CommonName"
	,f."Longitude"
	,f."Latitude"
	,t."Longitude"
	,t."Latitude"
