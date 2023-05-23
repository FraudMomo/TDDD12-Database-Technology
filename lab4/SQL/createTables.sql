USE `mohal573`; -- Change to your database name
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
