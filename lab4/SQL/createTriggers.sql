USE `mohal573`;
-- Change to your database name
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
