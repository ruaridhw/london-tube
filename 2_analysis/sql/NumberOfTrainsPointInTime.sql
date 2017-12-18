-- ---- sql_trains_point_in_time ----

WITH VehiclePointInTime AS (

SELECT
	 *
	 -- Calculate the number of minutes since @ArrivalTime only for trips arriving on or after @ArrivalTime
	,CASE WHEN "ArrivalMins_Link" - 540 < 0
		THEN NULL
		ELSE "ArrivalMins_Link" - 540
	 END AS "PosAtTime"
FROM departures
-- Filter to only trips that were online in the network as at @ArrivalTime
WHERE "VehicleJourneyCode" IN
	(
		SELECT "VehicleJourneyCode"
		FROM departures
		GROUP BY "VehicleJourneyCode"
		HAVING 540 BETWEEN MIN("DepartureMins_Link") AND MAX("ArrivalMins_Link")
	)
)

SELECT a.*
FROM VehiclePointInTime a
-- Filter previous query to one link per vehicle journey that is closest to @ArrivalTime
LEFT JOIN (

	SELECT "VehicleJourneyCode", MIN("PosAtTime") "MinPosAtTime"
	FROM VehiclePointInTime
	GROUP BY "VehicleJourneyCode"

) b ON a."VehicleJourneyCode" = b."VehicleJourneyCode"

WHERE "PosAtTime" = "MinPosAtTime"
ORDER BY "FromSequenceNumber"