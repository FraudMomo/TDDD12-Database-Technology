USE `mohal573`;
-- Change to your database name

/* ====== TABLES ====== */
SET FOREIGN_KEY_CHECKS = 0;

/* Drop tables */
DROP TABLE IF EXISTS Airport;
DROP TABLE IF EXISTS Route;
DROP TABLE IF EXISTS WeeklySchedule;
DROP TABLE IF EXISTS Weekday;
DROP TABLE IF EXISTS Year;
DROP TABLE IF EXISTS Flight;
DROP TABLE IF EXISTS Passenger;
DROP TABLE IF EXISTS Has_Reservation;
DROP TABLE IF EXISTS Reservation;
DROP TABLE IF EXISTS Booking;
DROP TABLE IF EXISTS PaymentCard;
DROP TABLE IF EXISTS Has_Ticket;
DROP TABLE IF EXISTS Is_Contact;

/* Enable foreign key checks */
SET FOREIGN_KEY_CHECKS = 1;

/* Create tables */
CREATE TABLE Airport
(
    `Code`    VARCHAR(3), -- Primary key
    `Name`    VARCHAR(30),
    `Country` VARCHAR(30),
    PRIMARY KEY (`Code`)
);

CREATE TABLE Year
(
    `Year`         INT, -- Primary key
    `ProfitFactor` DOUBLE,
    PRIMARY KEY (`Year`)
);

CREATE TABLE Route
(
    `ID`         INT AUTO_INCREMENT, -- Primary key
    `To`         VARCHAR(3),         -- Foreign key from table Airport.code
    `From`       VARCHAR(3),         -- Foreign key from table Airport.code
    `Year`       INT,                -- Foreign key from table Year.year
    `RoutePrice` DOUBLE,
    PRIMARY KEY (`ID`),
    FOREIGN KEY (`To`) REFERENCES Airport (`Code`),
    FOREIGN KEY (`From`) REFERENCES Airport (`Code`),
    FOREIGN KEY (`Year`) REFERENCES Year (`Year`)
);

CREATE TABLE Weekday
(
    `Weekday`       VARCHAR(30), -- Primary key (w/ Year)
    `Year`          INT,         -- Foreign key from table Year.year
    `WeekdayFactor` DOUBLE,
    PRIMARY KEY (`Weekday`, `Year`),
    FOREIGN KEY (`Year`) REFERENCES Year (`Year`)
);

CREATE TABLE WeeklySchedule
(
    `ID`              INT AUTO_INCREMENT, -- Primary key
    `Route`           INT,
    `TimeOfDeparture` TIME,
    `Weekday`         VARCHAR(30),        -- Foreign key from table Weekday.Weekday
    `Year`            INT,                -- Foreign key from table Weekday.Year
    PRIMARY KEY (`ID`),
    FOREIGN KEY (`Route`) REFERENCES Route (`ID`),
    FOREIGN KEY (`Weekday`) REFERENCES Weekday (`Weekday`)
);

CREATE TABLE Flight
(
    `FlightNumber` INT AUTO_INCREMENT, -- Primary key
    `WeeklyFlight` INT,                -- Foreign key from table WeeklySchedule.ID
    `Week`         INT,
    PRIMARY KEY (`FlightNumber`),
    FOREIGN KEY (`WeeklyFlight`) REFERENCES WeeklySchedule (ID)
);

CREATE TABLE Reservation
(
    `ReservationNumber` INT, -- Primary key
    `FlightNumber`      INT, -- Foreign key from table Flight.FlightNumber
    PRIMARY KEY (`ReservationNumber`),
    FOREIGN KEY (`FlightNumber`) REFERENCES Flight (`FlightNumber`)
);

CREATE TABLE PaymentCard
(
    `CardNumber` BIGINT, -- Primary key
    `CardHolder` VARCHAR(30),
    PRIMARY KEY (`CardNumber`)
);

CREATE TABLE Passenger
(
    `PassportNumber` INT, -- Primary key
    `Name`           VARCHAR(30),
    PRIMARY KEY (`PassportNumber`)
);

CREATE TABLE Has_Reservation
(
    `ReservationNumber` INT, -- Primary foreign key from table Reservation.ReservationNumber
    `PassportNumber`    INT, -- Primary foreign key from table Passenger.PassportNumber
    PRIMARY KEY (`ReservationNumber`, `PassportNumber`),
    FOREIGN KEY (`ReservationNumber`) REFERENCES Reservation (`ReservationNumber`),
    FOREIGN KEY (`PassportNumber`) REFERENCES Passenger (`PassportNumber`)
);

CREATE TABLE Booking
(
    `ReservationNumber` INT,    -- Primary foreign key from table Reservation.ReservationNumber
    `CardNumber`        BIGINT, -- Foreign key from table PaymentCard.CardNumber
    `Price`             DOUBLE,
    PRIMARY KEY (`ReservationNumber`),
    FOREIGN KEY (`ReservationNumber`) REFERENCES Reservation (`ReservationNumber`),
    FOREIGN KEY (`CardNumber`) REFERENCES PaymentCard (`CardNumber`)
);

CREATE TABLE Has_Ticket
(
    `ReservationNumber` INT, -- Primary foreign key from table Booking.ReservationNumber
    `PassportNumber`    INT, -- Primary foreign key from table Passenger.PassportNumber
    `TicketNumber`      INT,
    PRIMARY KEY (`ReservationNumber`, `PassportNumber`),
    FOREIGN KEY (`ReservationNumber`) REFERENCES Reservation (`ReservationNumber`),
    FOREIGN KEY (`PassportNumber`) REFERENCES Passenger (`PassportNumber`)
);

CREATE TABLE Is_Contact
(
    `ReservationNumber` INT, -- Primary foreign key from table Reservation.ReservationNumber
    `PassportNumber`    INT, -- Foreign key from table Passenger.PassportNumber
    `PhoneNumber`       BIGINT,
    `Email`             VARCHAR(30),
    PRIMARY KEY (`ReservationNumber`),
    FOREIGN KEY (`ReservationNumber`) REFERENCES Reservation (`ReservationNumber`),
    FOREIGN KEY (`PassportNumber`) REFERENCES Passenger (`PassportNumber`)
);

/* ====== FUNCTIONS ====== */
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
DELIMITER ;

/* ====== PROCEDURES ====== */
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

/* ======== TRIGGERS ======== */
DELIMITER //

/* Drop triggers */
DROP TRIGGER IF EXISTS generateTicketNumber;

/* Create triggers */
CREATE TRIGGER generateTicketNumber
    AFTER INSERT
    ON Booking
    FOR EACH ROW
BEGIN

    DECLARE passport_number INT;

    /* Cursor to iterate over passports */
    DECLARE passports_cursor CURSOR FOR
        SELECT PassportNumber
        FROM Has_Reservation
        WHERE ReservationNumber = NEW.ReservationNumber;

    /* If passport is not found or looped through all rows, set passport_number to NULL */
    DECLARE CONTINUE HANDLER FOR NOT FOUND
        SET passport_number = NULL;

    OPEN passports_cursor;
    PassportsLoop:
    LOOP
        FETCH passports_cursor INTO passport_number;
        IF passport_number IS NULL THEN
            LEAVE PassportsLoop;
        END IF;

        SET @TicketNumber = 0;
        SET @TicketNumberExists = 1;

        /* If TicketNumber already exists, generate new one */
        WHILE @TicketNumberExists
            DO
                /* Random number 1 to integer limit */
                SET @TicketNumber = FLOOR(RAND() * 2147483647);
                SET @TicketNumberExists = (SELECT COUNT(1)
                                           FROM Has_Ticket
                                           WHERE `TicketNumber` = @TicketNumber);
            END WHILE;

        INSERT INTO Has_Ticket (`TicketNumber`, `PassportNumber`, `ReservationNumber`)
        VALUES (@TicketNumber, passport_number, NEW.ReservationNumber);

    END LOOP;
    CLOSE passports_cursor;
END//
DELIMITER ;


/* ======== VIEWS ======== */

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
