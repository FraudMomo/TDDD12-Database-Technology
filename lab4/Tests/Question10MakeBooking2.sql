/******************************************************************************************
 Question 10, concurrency
 This is the second of two scripts that tests that the BryanAir database can handle concurrency.
 This script sets up a valid reservation and tries to pay for it in such a way that at most 
 one such booking should be possible (or the plane will run out of seats). This script should 
 be run in both terminals, in parallel. 
**********************************************************************************************/
SELECT "Testing script for Question 10, Adds a booking, should be run in both terminals" as "Message";
SELECT "Adding a reservations and passengers" as "Message";
CALL addReservation("MIT","HOB",2010,1,"Monday","09:00:00",21,@a); 
CALL addPassenger(@a,00000001,"Saruman");
CALL addPassenger(@a,00000002,"Orch1");
CALL addPassenger(@a,00000003,"Orch2");
CALL addPassenger(@a,00000004,"Orch3");
CALL addPassenger(@a,00000005,"Orch4");
CALL addPassenger(@a,00000006,"Orch5");
CALL addPassenger(@a,00000007,"Orch6");
CALL addPassenger(@a,00000008,"Orch7");
CALL addPassenger(@a,00000009,"Orch8");
CALL addPassenger(@a,00000010,"Orch9");
CALL addPassenger(@a,00000011,"Orch10");
CALL addPassenger(@a,00000012,"Orch11");
CALL addPassenger(@a,00000013,"Orch12");
CALL addPassenger(@a,00000014,"Orch13");
CALL addPassenger(@a,00000015,"Orch14");
CALL addPassenger(@a,00000016,"Orch15");
CALL addPassenger(@a,00000017,"Orch16");
CALL addPassenger(@a,00000018,"Orch17");
CALL addPassenger(@a,00000019,"Orch18");
CALL addPassenger(@a,00000020,"Orch19");
CALL addPassenger(@a,00000021,"Orch20");
CALL addContact(@a,00000001,"saruman@magic.mail",080667989); 
SELECT SLEEP(5);
SELECT "Making payment, supposed to work for one session and be denied for the other" as "Message";
LOCK TABLES Booking WRITE, Has_Reservation WRITE, Reservation WRITE, PaymentCard WRITE, WeeklySchedule READ, Weekday READ, Route READ, Year READ, Flight WRITE, Has_Ticket WRITE, Is_Contact WRITE;
CALL addPayment (@a, "Sauron",7878787878);
UNLOCK TABLES;
SELECT "Nr of free seats on the flight (should be 19 if no overbooking occured, otherwise -2): " as "Message", (SELECT nr_of_free_seats from allFlights where departure_week = 1) as "nr_of_free_seats";

  


