USE `mohal573`; -- Change to your database name
DELIMITER // -- Multiple statements

/* Drop procedures */
DROP PROCEDURE IF EXISTS addYear;
DROP PROCEDURE IF EXISTS addDay;
DROP PROCEDURE IF EXISTS addDestination;
DROP PROCEDURE IF EXISTS addRoute;
DROP PROCEDURE IF EXISTS addFlight;
DROP PROCEDURE IF EXISTS addReservation;
DROP PROCEDURE IF EXISTS addPassenger;
DROP PROCEDURE IF EXISTS addContact;
DROP PROCEDURE IF EXISTS addPayment;

/* Create procedures */
/* addYear */
CREATE PROCEDURE addYear(IN year INT, factor DOUBLE)
BEGIN
    INSERT INTO Year (`Year`, `ProfitFactor`)
    VALUES (year, factor);
END//

/* addDay */
CREATE PROCEDURE addDay(IN year INT, day VARCHAR(30), factor DOUBLE)
BEGIN
    INSERT INTO Weekday (`Weekday`, `Year`, `WeekdayFactor`)
    VALUES (day, year, factor);
END//

/* addDestination */
CREATE PROCEDURE addDestination(IN airport_code VARCHAR(3), name VARCHAR(30), country VARCHAR(30))
BEGIN
    INSERT INTO Airport (`Code`, `Name`, `Country`)
    VALUES (airport_code, name, country);
END//

/* addRoute */
CREATE PROCEDURE addRoute(IN departure_airport_code VARCHAR(3), arrival_airport_code VARCHAR(3), year INT,
                          route_price DOUBLE)
BEGIN
    INSERT INTO Route (`To`, `From`, `Year`, `RoutePrice`)
    VALUES (arrival_airport_code, departure_airport_code, year, route_price);
END//

/* addFlight */
CREATE PROCEDURE addFlight(IN departure_airport_code VARCHAR(3), arrival_airport_code VARCHAR(3), year INT,
                           day VARCHAR(30), departure_time TIME)
BEGIN
    /* Find the route ID */
    SET @RouteID = (SELECT ID
                    FROM Route
                    WHERE `To` = arrival_airport_code
                      AND `From` = departure_airport_code
                      AND Route.Year = year);

    /* Insert into weekly schedule */
    INSERT INTO WeeklySchedule (`Route`, `TimeOfDeparture`, `Weekday`, `Year`)
    VALUES (@RouteID, departure_time, day, year);

    /* Find the weekly flight ID */
    SET @WeeklyFlightID = LAST_INSERT_ID();

    /* Insert into flight for each week (52) in year */
    SET @i = 1;
    WHILE @i <= 52
        DO
            INSERT INTO Flight (`WeeklyFlight`, `Week`)
            VALUES (@WeeklyFlightID, @i);
            SET @i = @i + 1;
        END WHILE;
END//

/* addReservation */
CREATE PROCEDURE addReservation(IN departure_airport_code VARCHAR(3), arrival_airport_code VARCHAR(3), flight_year INT,
                                flight_week INT, flight_day VARCHAR(30), time TIME, number_of_passengers INT,
                                OUT output_reservation_nr INT)
BEGIN
    SET @RouteID = (SELECT ID
                    FROM Route
                    WHERE `To` = arrival_airport_code
                      AND `From` = departure_airport_code
                      AND `Year` = flight_year);

    IF (@RouteID IS NULL) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Route does not exist';
    END IF;

    SET @WeeklyFlightID = (SELECT ID
                           FROM WeeklySchedule
                           WHERE `Route` = @RouteID
                             AND `TimeOfDeparture` = time
                             AND `Weekday` = flight_day
                             AND `Year` = flight_year);

    IF (@WeeklyFlightID IS NULL) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Weekly flight does not exist';
    END IF;

    SET @FlightNumber = (SELECT FlightNumber
                         FROM Flight
                         WHERE `WeeklyFlight` = @WeeklyFlightID
                           AND `Week` = flight_week);

    IF (@FlightNumber IS NULL) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Flight does not exist';
    END IF;

    /* If there are enough seats on the flight, generate a reservation number and insert into reservation */
    IF (calculateFreeSeats(@FlightNumber) >= number_of_passengers) THEN
        SET @ReservationNumberExists = 1;

        /* If ReservationNumber already exists, generate new one */
        WHILE @ReservationNumberExists
            DO
                /* Random number 1 to integer limit */
                SET output_reservation_nr = FLOOR(RAND() * 2147483647);
                SET @ReservationNumberExists = (SELECT COUNT(1)
                                                FROM Reservation
                                                WHERE `ReservationNumber` = output_reservation_nr);
            END WHILE;

        /* Insert reservation to flight in Reservation */
        INSERT INTO Reservation (`ReservationNumber`, `FlightNumber`)
        VALUES (output_reservation_nr, @FlightNumber);
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Not enough seats on flight';
    END IF;
END//

/* addPassenger */
CREATE PROCEDURE addPassenger(IN reservation_nr INT, passport_number INT, name VARCHAR(30))
BEGIN

    /* Check if reservation exists */
    IF (!reservationExists(reservation_nr)) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Reservation does not exist';
    END IF;

    /* Check if booking exists (already paid) */
    IF (bookingExists(reservation_nr)) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Booking is already paid, unable to add new passengers.';
    END IF;

    /* Add passenger to Passenger */
    IF (!passengerExists(passport_number)) THEN
        INSERT INTO Passenger (`PassportNumber`, `Name`)
        VALUES (passport_number, name);
    END IF;

    /* Add passenger to Has_Reservation */
    IF (!passengerHasReservation(reservation_nr, passport_number)) THEN
        INSERT INTO Has_Reservation (`ReservationNumber`, `PassportNumber`)
        VALUES (reservation_nr, passport_number);
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Passenger already has reservation';
    END IF;
END//

/* addContact */
CREATE PROCEDURE addContact(IN reservation_nr INT, passport_number INT, email VARCHAR(30), phone BIGINT)
BEGIN
    /* Check Reservation */
    IF (!reservationExists(reservation_nr)) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Reservation does not exist';
    END IF;

    /* Check passenger */
    IF (passengerExists(passport_number)) THEN
        /* Add passenger to Is_Contact */
        IF (!contactExists(reservation_nr))
        THEN
            INSERT INTO Is_Contact (`ReservationNumber`, `PassportNumber`, `PhoneNumber`, `Email`)
            VALUES (reservation_nr, passport_number, phone, email);
        ELSE
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Contact already exists';
        END IF;
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Passenger is not part of reservation';
    END IF;
END//

/* addPayment */
CREATE PROCEDURE addPayment(IN reservation_nr INT, cardholder_name VARCHAR(30), credit_card_number BIGINT)
BEGIN
    /* Check reservation */
    IF (!reservationExists(reservation_nr))
    THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Reservation does not exist';
    END IF;

    /* Check if already paid */
    IF (bookingExists(reservation_nr)) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Booking is already paid';
    END IF;

    /* If reservation has a contact */
    IF (contactExists(reservation_nr)) THEN
        /* Get flight number */
        IF (reservationExists(reservation_nr)) THEN
            SET @FlightNumber = (SELECT FlightNumber
                                 FROM Reservation
                                 WHERE ReservationNumber = reservation_nr);
        ELSE
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Reservation does not exist';
        END IF;

        /* Total unpaid seats */
        SET @FreeSeats = calculateFreeSeats(@FlightNumber);
        /* Total seats for reservation, to avoid overbooking */
        SET @totalPassengers = getTotalPassengersForReservation(reservation_nr);

        IF (@FreeSeats > 0 AND @FreeSeats >= @totalPassengers) THEN
            /* Add payment information to PaymentCard if it does not exist */
            IF (!paymentCardExists(credit_card_number))
            THEN
                INSERT INTO PaymentCard (`CardNumber`, `CardHolder`)
                VALUES (credit_card_number, cardholder_name);
            END IF;

            -- SELECT SLEEP(5); For testing Question 10c

            /* Add payment information to Booking */
            INSERT INTO Booking (`ReservationNumber`, `CardNumber`, `Price`)
            VALUES (reservation_nr, credit_card_number, calculatePrice(@FlightNumber));

        ELSE
            IF (!deleteReservation(reservation_nr)) THEN
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Not enough seats on plane, could not delete reservation.';
            END IF;
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Not enough seats on plane, deleting reservation.';
        END IF;
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Reservation does not have a contact';
    END IF;
END//
DELIMITER ;