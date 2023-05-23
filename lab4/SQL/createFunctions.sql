USE `mohal573`;
-- Change to your database name

/* Drop functions */
DROP FUNCTION IF EXISTS calculateFreeSeats;
DROP FUNCTION IF EXISTS calculatePrice;
DROP FUNCTION IF EXISTS reservationExists;
DROP FUNCTION IF EXISTS passengerExists;
DROP FUNCTION IF EXISTS passengerHasReservation;
DROP FUNCTION IF EXISTS contactExists;
DROP FUNCTION IF EXISTS bookingExists;
DROP FUNCTION IF EXISTS paymentCardExists;
DROP FUNCTION IF EXISTS getTotalPassengersForReservation;
DROP FUNCTION IF EXISTS deleteReservation;

/* Create functions */
-- Returns number of free (unpaid) seats
CREATE FUNCTION calculateFreeSeats(flight_number INT) RETURNS INT
BEGIN
    DECLARE reservation_number INT;
    DECLARE booked_seats INT;
    DECLARE total_seats INT;

    /* Cursor to iterate over reservations */
    DECLARE reservation_cursor CURSOR FOR
        SELECT ReservationNumber
        FROM Reservation
        WHERE `FlightNumber` = flight_number;

    /* If no reservations are found, set reservation_number to NULL */
    DECLARE CONTINUE HANDLER FOR NOT FOUND
        SET reservation_number = NULL;

    SET booked_seats = 0;
    SET total_seats = 40;

    OPEN reservation_cursor;
    ReservationsLoop:
    LOOP
        FETCH reservation_cursor INTO reservation_number;

        IF reservation_number IS NULL THEN
            LEAVE ReservationsLoop;
        END IF;

        /* Add number of passengers in reservation to booked_seats */
        SET booked_seats = booked_seats + (SELECT COUNT(*)
                                           FROM Has_Ticket
                                           WHERE `ReservationNumber` = reservation_number);

    END LOOP;
    CLOSE reservation_cursor;

    RETURN total_seats - booked_seats;
END;

-- Returns calculated price of the next seat
CREATE FUNCTION calculatePrice(flight_number INT) RETURNS DOUBLE
BEGIN
    DECLARE Weekly_Flight INT;
    DECLARE Route_ID INT;
    DECLARE Week_day VARCHAR(30);
    DECLARE WS_Year INT;
    DECLARE Route_Price DOUBLE;
    DECLARE Weekday_Factor DOUBLE;
    DECLARE Booked_Passengers INT;
    DECLARE Profit_Factor DOUBLE;
    DECLARE Total_Seats INT;
    SET Total_Seats = 40;

    SELECT WeeklyFlight
    INTO Weekly_Flight
    FROM Flight
    WHERE `FlightNumber` = flight_number;

    /* Get Route WeekDay and Year from WeeklySchedule */
    SELECT Route, Weekday, Year
    INTO Route_ID, Week_day, WS_Year
    FROM WeeklySchedule
    WHERE ID = Weekly_Flight;

    SET Route_Price = (SELECT RoutePrice
                       FROM Route
                       WHERE ID = Route_ID);

    SET Weekday_Factor = (SELECT WeekdayFactor
                          FROM Weekday
                          WHERE Weekday = Week_day
                            AND Year = WS_Year);

    SET Booked_Passengers = Total_Seats - calculateFreeSeats(flight_number);

    SET Profit_Factor = (SELECT ProfitFactor
                         FROM Year
                         WHERE Year = WS_Year);

    RETURN Route_Price * Weekday_Factor * Profit_Factor * (Booked_Passengers + 1) / 40;
END;

CREATE FUNCTION reservationExists(reservation_number INT) RETURNS BOOLEAN
BEGIN
    IF ((SELECT COUNT(1)
         FROM Reservation
         WHERE `ReservationNumber` = reservation_number) = 0) THEN
        RETURN FALSE;
    ELSE
        RETURN TRUE;
    END IF;
END;

CREATE FUNCTION passengerExists(passport_number INT) RETURNS BOOLEAN
BEGIN
    IF ((SELECT COUNT(1)
         FROM Passenger
         WHERE `PassportNumber` = passport_number) = 0) THEN
        RETURN FALSE;
    ELSE
        RETURN TRUE;
    END IF;
END;

CREATE FUNCTION passengerHasReservation(reservation_number INT, passport_number INT) RETURNS BOOLEAN
BEGIN
    IF ((SELECT COUNT(1)
         FROM Has_Reservation
         WHERE `ReservationNumber` = reservation_number
           AND `PassportNumber` = passport_number) = 0) THEN
        RETURN FALSE;
    ELSE
        RETURN TRUE;
    END IF;
END;

CREATE FUNCTION contactExists(reservation_number INT) RETURNS BOOLEAN
BEGIN
    IF ((SELECT COUNT(1)
         FROM Is_Contact
         WHERE `ReservationNumber` = reservation_number) = 0) THEN
        RETURN FALSE;
    ELSE
        RETURN TRUE;
    END IF;
END;

CREATE FUNCTION bookingExists(reservation_number INT) RETURNS BOOLEAN
BEGIN
    IF ((SELECT COUNT(1)
         FROM Booking
         WHERE `ReservationNumber` = reservation_number) = 0) THEN
        RETURN FALSE;
    ELSE
        RETURN TRUE;
    END IF;
END;

CREATE FUNCTION paymentCardExists(card_number BIGINT) RETURNS BOOLEAN
BEGIN
    IF ((SELECT COUNT(1)
         FROM PaymentCard
         WHERE `CardNumber` = card_number) = 0) THEN
        RETURN FALSE;
    ELSE
        RETURN TRUE;
    END IF;
END;

CREATE FUNCTION getTotalPassengersForReservation(reservation_number INT) RETURNS BOOLEAN
BEGIN
    SET @totalPassengers = (SELECT COUNT(*)
                            FROM Has_Reservation
                            WHERE `ReservationNumber` = reservation_number);
    RETURN @totalPassengers;
END;

/* Only deletes reservation, keeps passenger data */
DELIMITER //
CREATE FUNCTION deleteReservation(reservation_number INT) RETURNS BOOLEAN
BEGIN
    /* Delete from Is_Contact */
    DELETE
    FROM Is_Contact
    WHERE `ReservationNumber` = reservation_number;

    /* Delete from Has_Reservation */
    DELETE
    FROM Has_Reservation
    WHERE `ReservationNumber` = reservation_number;

    /* Delete from Reservation */
    DELETE
    FROM Reservation
    WHERE `ReservationNumber` = reservation_number;

    /* If reservation still exists, operation has failed */
    IF (reservationExists(reservation_number)) THEN
        RETURN FALSE;
    ELSE
        RETURN TRUE;
    END IF;
END//