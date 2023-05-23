USE `mohal573`;
-- Change to your database name

/* Drop view */
DROP VIEW IF EXISTS allFlights;

/* Creates a view with all flights and their information */
CREATE VIEW allFlights AS
SELECT departureCity.Name                 AS departure_city_name,
       destinationCity.Name               AS destination_city_name,
       ws.TimeOfDeparture                 AS departure_time,
       ws.Weekday                         AS departure_day,
       f.Week                             AS departure_week,
       ws.Year                            AS departure_year,
       calculateFreeSeats(f.FlightNumber) AS nr_of_free_seats,
       calculatePrice(f.FlightNumber)     AS current_price_per_seat
FROM Flight f
         JOIN WeeklySchedule ws ON f.WeeklyFlight = ws.ID
         JOIN Route r ON ws.Route = r.ID
         JOIN Airport departureCity ON r.`From` = departureCity.Code
         JOIN Airport destinationCity ON r.`To` = destinationCity.Code;
