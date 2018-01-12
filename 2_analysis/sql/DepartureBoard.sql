--' ---
--' title: "Departure Board"
--' ---
--' 
--' PostgreSQL function which takes an ISO formatted date as input
--' and returns a table all train departures for that day.
--' 
--' Each row represents the movement of one vehicle from
--' a StopPoint to the successive StopPoint.
--'
--' [Source code](https://github.com/ruaridhw/london-tube/blob/master/2_analysis/sql/DepartureBoard.sql)
-- ---- sql_departures, engine='sql'
CREATE OR REPLACE FUNCTION departureboard(IN _timetable_date text)
  RETURNS TABLE (
    "VehicleJourneyCode" text,
    "Line" text,
    "From_VehicleSequenceNumber" integer,
    "From_StopPointRef" text,
    "From_StopPointName" text,
    "From_Longitude" double precision,
    "From_Latitude" double precision,
    "To_VehicleSequenceNumber" integer,
    "To_StopPointRef" text,
    "To_StopPointName" text,
    "To_Longitude" double precision,
    "To_Latitude" double precision,
    "JourneyTime"	double precision,
    "DepartureMins_Link" double precision,
    "ArrivalMins_Link" double precision,
    "Flag_LastStop"	boolean
  )

  AS

  $BODY$

  SELECT

     "VehicleJourneyCode"
     -- Extract three-letter line abbreviation
    ,SUBSTRING("LineRef" FROM 3 FOR 3) "Line"
    ,CAST("From_VehicleSequenceNumber" as int) "From_VehicleSequenceNumber"
    ,"From_StopPointRef"
    ,"From_StopPointName"
    ,"From_Longitude"
    ,"From_Latitude"
    -- Re-create SequenceNumber for each vehicle
    ,CAST("From_VehicleSequenceNumber" + 1 as int) "To_VehicleSequenceNumber"
    ,"To_StopPointRef"
    ,"To_StopPointName"
    ,"To_Longitude"
    ,"To_Latitude"
    ,"JourneyTime"
    -- DepartureMins_Link is the ArrivalMins_Link of the previous row
    -- partitioned by vehicle and ordered by stop sequence
    ,LAG("ArrivalMins_Link", 1, "DepartureMins") OVER
      (PARTITION BY "VehicleJourneyCode" ORDER BY "From_SequenceNumber")
      AS "DepartureMins_Link"
    ,"ArrivalMins_Link"
    ,"Flag_LastStop"

  FROM (

    SELECT

       v."VehicleJourneyCode"
      ,v."LineRef"
      ,v."DepartureMins"

      ,j."From_SequenceNumber"
      -- Re-create SequenceNumber for each vehicle by ranking the current SequenceNumber
      -- within a vehicle partition
      ,RANK() OVER (PARTITION BY v."VehicleJourneyCode" ORDER BY j."From_SequenceNumber")
        "From_VehicleSequenceNumber"
      ,j."From_StopPointRef"
      ,p1."CommonName" "From_StopPointName"
      ,p1."Longitude" "From_Longitude"
      ,p1."Latitude" "From_Latitude"
      ,j."To_StopPointRef"
      ,p2."CommonName" "To_StopPointName"
      ,p2."Longitude" "To_Longitude"
      ,p2."Latitude" "To_Latitude"

      ,j."JourneyTime"
      -- Create ArrivalMins_Link as DepartureMins plus the cumulative JourneyTime
      ,v."DepartureMins" + SUM(j."JourneyTime") OVER
        (PARTITION BY v."VehicleJourneyCode" ORDER BY j."From_SequenceNumber")
        AS "ArrivalMins_Link"
      -- Flag whether the current To_SequenceNumber is the greatest within a
      -- Vehicle partition
      ,j."To_SequenceNumber" = MAX(j."To_SequenceNumber") OVER
        (PARTITION BY v."VehicleJourneyCode") AS "Flag_LastStop"

    /* Journey and Timing Link Tables */
    FROM "VehicleJourneys" v
    LEFT JOIN "JourneyPatterns" s
      ON s."JourneyPattern" = v."JourneyPatternRef"
    LEFT JOIN "JourneyPatternTimingLinks" j
      ON j."JourneyPatternSections" = s."JourneyPatternSectionRefs"

    /* Stop Names */
    LEFT JOIN "StopPoints" p1
      ON p1."AtcoCode" = j."From_StopPointRef"
    LEFT JOIN "StopPoints" p2
      ON p2."AtcoCode" = j."To_StopPointRef"

    /* Operating Periods and Operating Profiles */
    LEFT JOIN "Services_RegularDayType_DaysOfWeek" d1
      ON d1."Services" = v."ServiceRef"
    LEFT JOIN "VehicleJourneys_RegularDayType_DaysOfWeek" d2
      ON d2."VehicleJourneys" = v."VehicleJourneyCode"
    LEFT JOIN "Services" b
      ON b."ServiceCode" = v."ServiceRef"

    WHERE
    -- Filter to timetables that have services and journeys on _timetable_date day of the week
          d1."DaysOfWeek" IN (SELECT "DayGroup" FROM DaysOfWeek_Groups
                              WHERE "DayIndex" = DATE_PART('ISODOW',
                                                           CAST(_timetable_date AS date)))
      AND d2."DaysOfWeek" IN (SELECT "DayGroup" FROM DaysOfWeek_Groups
                              WHERE "DayIndex" = DATE_PART('ISODOW',
                                                           CAST(_timetable_date AS date)))

    -- Filter to timetables that are operating on _timetable_date
      AND CAST(_timetable_date AS date) BETWEEN b."OpPeriod_StartDate" AND b."OpPeriod_EndDate"

  ) arrival_calc

  $BODY$ LANGUAGE sql;
