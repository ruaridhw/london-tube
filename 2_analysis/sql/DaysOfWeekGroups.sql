--' ---
--' title: "Days of Weeks Groups"
--' ---
--' 
--' PostgreSQL table containing the mapping
--' of "Day of Week" Index (1 = Monday to 7 = Sunday) with
--' the various Operating Profile groups to which they belong
--' 
--' eg. 1 maps to Monday, MondayToFriday, MondayToSaturday, MondayToSunday
--'     7 maps to Sunday, MondayToSunday, Weekend
--' 
--' [Source code](https://github.com/ruaridhw/london-tube/blob/master/2_analysis/sql/DaysOfWeekGroups.sql)
-- ---- sql_daysofweeks, engine='sql'
CREATE TABLE DaysOfWeek_Groups AS (

  /*

  -- Find various "DaysOfWeek" groupings

  SELECT "DaysOfWeek" FROM (

  SELECT DISTINCT "DaysOfWeek" FROM "VehicleJourneys_RegularDayType_DaysOfWeek"
  UNION
  SELECT DISTINCT "DaysOfWeek" FROM "Services_RegularDayType_DaysOfWeek"
  ) A
  WHERE "DaysOfWeek" NOT IN (

  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday'
  )

  */

  /*
  MondayToFriday
  MondayToSaturday
  MondayToSunday
  Weekend
  */

  --TODO move table creation to R or Python to avoid abusing SQL...

  SELECT *
  FROM (SELECT generate_series(1, 5) "DayIndex") A, (SELECT 'MondayToFriday' "DayGroup") B

  UNION

  SELECT *
  FROM (SELECT generate_series(1, 6) "DayIndex") A, (SELECT 'MondayToSaturday' "DayGroup") B

  UNION

  SELECT *
  FROM (SELECT generate_series(1, 7) "DayIndex") A, (SELECT 'MondayToSunday' "DayGroup") B

  UNION

  SELECT *
  FROM (SELECT generate_series(6, 7) "DayIndex") A, (SELECT 'Weekend' "DayGroup") B

  UNION

  SELECT 1, 'Monday' UNION
  SELECT 2, 'Tuesday' UNION
  SELECT 3, 'Wednesday' UNION
  SELECT 4, 'Thursday' UNION
  SELECT 5, 'Friday' UNION
  SELECT 6, 'Saturday' UNION
  SELECT 7, 'Sunday'


)
