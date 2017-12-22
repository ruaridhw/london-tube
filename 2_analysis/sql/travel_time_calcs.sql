-- ---- sql_view_departures ----

CREATE MATERIALIZED VIEW departures AS

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

		,v."DepartureMins" + SUM(j."JourneyTime") OVER (PARTITION BY v."VehicleJourneyCode" ORDER BY j."From_SequenceNumber") AS "ArrivalMins_Link"
		,j."To_SequenceNumber" = MAX(j."To_SequenceNumber") OVER (PARTITION BY v."VehicleJourneyCode") AS "Flag_LastStop"
		
		/* Used for debugging
		,FIRST_VALUE(p1."CommonName") OVER (PARTITION BY v."VehicleJourneyCode"
		    ORDER BY j."From_SequenceNumber" ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS "OriginStopPointName"

		,LAST_VALUE(p2."CommonName") OVER (PARTITION BY v."VehicleJourneyCode"
		    ORDER BY j."From_SequenceNumber" ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS "DestStopPointName"
		*/
		
	FROM "VehicleJourneys" v

	LEFT JOIN "JourneyPatterns" s
	ON v."JourneyPatternRef" = s."JourneyPattern"

	LEFT JOIN "JourneyPatternTimingLinks" j
	ON s."JourneyPatternSectionRefs" = j."JourneyPatternSections"

	LEFT JOIN "StopPoints" p1
	ON j."From_StopPointRef" = p1."AtcoCode"

	LEFT JOIN "StopPoints" p2
	ON j."To_StopPointRef" = p2."AtcoCode"

	LEFT JOIN "Services_RegularDayType_DaysOfWeek" d1
	ON d1."Services" = v."ServiceRef"

	LEFT JOIN "VehicleJourneys_RegularDayType_DaysOfWeek" d2
	ON d2."VehicleJourneys" = v."VehicleJourneyCode"

	LEFT JOIN "Services" b
	ON b."ServiceCode" = v."ServiceRef"

	WHERE
		    d1."DaysOfWeek" IN ('MondayToSaturday', 'MondayToSunday', 'Wednesday')
		AND d2."DaysOfWeek" IN ('MondayToSaturday', 'MondayToSunday', 'Wednesday')

	AND '2017-12-20' BETWEEN b."OpPeriod_StartDate" AND b."OpPeriod_EndDate"

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
