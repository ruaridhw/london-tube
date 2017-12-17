-- SELECT JourneyPatternRef, DepartureMins, COUNT(*)
-- FROM VehicleJourneys
-- GROUP BY JourneyPatternRef, DepartureMins
-- HAVING COUNT(*) > 1

-- ---- sql_view_departures ----

CREATE OR REPLACE VIEW departures AS

WITH arrival_calc AS (
	SELECT

		 v.*
		,j."JourneyPatternSections"
		,j."JourneyPatternTimingLink"
		
		,j."From_SequenceNumber"
		,j."From_StopPointRef"
		,p1."CommonName" "FromStopPointName"
		
		,j."To_SequenceNumber"
		,j."To_StopPointRef"
		,p2."CommonName" "ToStopPointName"
		
		,j."RunTime"
		,j."WaitTime"
		,j."JourneyTime"
		
		--,arr."ArrivalMins_Link"
		,v."DepartureMins" + SUM(j."JourneyTime") OVER (PARTITION BY v."VehicleJourneyCode" ORDER BY j."From_SequenceNumber") AS "ArrivalMins_Link"
		
		,FIRST_VALUE(p1."CommonName") OVER (PARTITION BY v."VehicleJourneyCode"
		    ORDER BY j."From_SequenceNumber" ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS "OriginStopPointName"
		
		,LAST_VALUE(p2."CommonName") OVER (PARTITION BY v."VehicleJourneyCode"
		    ORDER BY j."From_SequenceNumber" ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS "DestStopPointName"

	FROM "VehicleJourneys" v

	LEFT JOIN "JourneyPatterns" s
	ON v."JourneyPatternRef" = s."JourneyPattern"

	LEFT JOIN "JourneyPatternTimingLinks" j
	ON s."JourneyPatternSectionRefs" = j."JourneyPatternSections"

	LEFT JOIN "StopPoints" p1
	ON j."From_StopPointRef" = p1."AtcoCode"

	LEFT JOIN "StopPoints" p2
	ON j."To_StopPointRef" = p2."AtcoCode"

	--,LATERAL (SELECT v."DepartureMins" + SUM(j."JourneyTime") OVER (PARTITION BY v."VehicleJourneyCode" ORDER BY j."FromSequenceNumber") AS "ArrivalMins_Link") arr

	--WHERE v."JourneyPatternRef" = 'JP_1-BAK-_-y05-430200-228-I-16'
	--WHERE v.DepartureMins BETWEEN 561 AND 563
	ORDER BY v."DepartureMins", j."From_SequenceNumber"

)

SELECT
	 *
	,LAG("ArrivalMins_Link", 1, "DepartureMins") OVER (PARTITION BY "VehicleJourneyCode" ORDER BY "From_SequenceNumber") AS "DepartureMins_Link"
FROM arrival_calc

-- SELECT 
-- FROM JourneyPatternSections j
-- ON JourneyPatternSectionID = JourneyPatternSectionRefs
-- 
-- SELECT JourneyPatternID, JourneyPatternSectionRefs	
-- FROM StandardServices s