/* Welcome to the SQL mini project. You will carry out this project partly in
the PHPMyAdmin interface, and partly in Jupyter via a Python connection.

This is Tier 2 of the case study, which means that there'll be less guidance for you about how to setup
your local SQLite connection in PART 2 of the case study. This will make the case study more challenging for you: 
you might need to do some digging, aand revise the Working with Relational Databases in Python chapter in the previous resource.

Otherwise, the questions in the case study are exactly the same as with Tier 1. 

PART 1: PHPMyAdmin
You will complete questions 1-9 below in the PHPMyAdmin interface. 
Log in by pasting the following URL into your browser, and
using the following Username and Password:

URL: https://sql.springboard.com/
Username: student
Password: learn_sql@springboard

The data you need is in the "country_club" database. This database
contains 3 tables:
    i) the "Bookings" table,
    ii) the "Facilities" table, and
    iii) the "Members" table.

In this case study, you'll be asked a series of questions. You can
solve them using the platform, but for the final deliverable,
paste the code for each solution into this script, and upload it
to your GitHub.

Before starting with the questions, feel free to take your time,
exploring the data, and getting acquainted with the 3 tables. */


/* QUESTIONS 
/* Q1: Some of the facilities charge a fee to members, but some do not.
Write a SQL query to produce a list of the names of the facilities that do. */
SELECT Distinct(name)
FROM Facilities
WHERE membercost != 0.0

/*OUTPUT
name
Tennis Court 1
Tennis Court 2
Massage Room 1
Massage Room 2
Squash Court
*/


/* Q2: How many facilities do not charge a fee to members? */
SELECT COUNT(name)
FROM Facilities
WHERE membercost = 0.0

/*OUTPUT
COUNT(name)
4
*/

/* Q3: Write an SQL query to show a list of facilities that charge a fee to members,
where the fee is less than 20% of the facility's monthly maintenance cost.
Return the facid, facility name, member cost, and monthly maintenance of the
facilities in question. */
SELECT facid, name, membercost, monthlymaintenance
FROM Facilities
WHERE membercost/monthlymaintenance < 0.2;

/*
OUTPUT
facid, name, membercost, monthlymaintenance
0, Tennis Court 1, 5.0, 200
1, Tennis Court 2, 5.0, 200
2, Badminton Court, 0.0, 50
3, Table Tennis, 0.0, 10 
4, Massage Room 1, 9.9, 3000
5, Massage Room 2, 9.9, 3000
6, Squash Court, 3.5, 80
7, Snooker Table, 0.0, 15
8, Pool Table, 0.0, 15
*/


/* Q4: Write an SQL query to retrieve the details of facilities with ID 1 and 5.
Try writing the query without using the OR operator. */
SELECT * 
FROM Facilities
WHERE facid = 1 OR facid = 5;


/* Q5: Produce a list of facilities, with each labelled as
'cheap' or 'expensive', depending on if their monthly maintenance cost is
more than $100. Return the name and monthly maintenance of the facilities
in question. */
SELECT name, monthlymaintenance,
	CASE 
		WHEN monthlymaintenance > 100 THEN 'expensive'
		ELSE 'cheap' 
	END AS cost_cat
FROM Facilities


/* Q6: You'd like to get the first and last name of the last member(s)
who signed up. Try not to use the LIMIT clause for your solution. */
SELECT firstname, surname
FROM Members
WHERE date(joindate) = (SELECT MAX(date(joindate)) FROM Members)


/* Q7: Produce a list of all members who have used a tennis court.
Include in your output the name of the court, and the name of the member
formatted as a single column. Ensure no duplicate data, and order by
the member name. */
set sql_mode=PIPES_AS_CONCAT;

SELECT DISTINCT m.firstname||' '||m.surname as wholename, f.name
FROM Members as m
LEFT JOIN Bookings as b
ON m.memid = b.memid
LEFT JOIN Facilities as f
ON f.facid = b.facid
HAVING f.name LIKE "Tennis Court%" AND wholename NOT LIKE "GUEST%"
ORDER BY wholename


/* Q8: Produce a list of bookings on the day of 2012-09-14 which
will cost the member (or guest) more than $30. Remember that guests have
different costs to members (the listed costs are per half-hour 'slot'), and
the guest user's ID is always 0. Include in your output the name of the
facility, the name of the member formatted as a single column, and the cost.
Order by descending cost, and do not use any subqueries. */

set sql_mode=PIPES_AS_CONCAT;

SELECT f.name, m.firstname||' '||m.surname as wholename, CASE
	WHEN b.memid = 0 THEN b.slots*f.guestcost
	ELSE b.slots*f.membercost
	END AS cost
FROM Bookings as b JOIN Facilities as f
ON b.facid = f.facid
JOIN Members as m
ON b.memid = m.memid
WHERE DATE(b.starttime) = '2012-09-14'
having cost > 30.0


/* Q9: This time, produce the same result as in Q8, but using a subquery. */

set sql_mode=PIPES_AS_CONCAT;

SELECT fac, wholename, cost

FROM (
    SELECT f.name as fac, 
    m.firstname||' '||m.surname as wholename,
    CASE
    	WHEN b.memid = 0 THEN b.slots * f.guestcost
    	ELSE b.slots * f.membercost END AS cost,
    b.starttime
    FROM Bookings as b JOIN Facilities as f
    ON b.facid = f.facid
    JOIN Members as m
    ON b.memid = m.memid
) as tbl1
WHERE date(starttime) = '2012-09-14' and cost > 30.0



/* PART 2: SQLite

Export the country club data from PHPMyAdmin, and connect to a local SQLite instance from Jupyter notebook 
for the following questions.  

QUESTIONS:
/* Q10: Produce a list of facilities with a total revenue less than 1000.
The output of facility name and total revenue, sorted by revenue. Remember
that there's a different cost for guests and members! */
SELECT fac, SUM(cost) as revenue

FROM (
    SELECT f.name as fac, 
    m.firstname||' '||m.surname as wholename,
    CASE
        WHEN b.memid = 0 THEN b.slots * f.guestcost
        ELSE b.slots * f.membercost END AS cost,
    b.starttime
    FROM Bookings as b JOIN Facilities as f
    ON b.facid = f.facid
    JOIN Members as m
    ON b.memid = m.memid 
)
GROUP BY fac
HAVING revenue < 1000

/* Q11: Produce a report of members and who recommended them in alphabetic surname,firstname order */
SELECT m1.surname, m1.firstname, m2.firstname||' '||m2.surname as recommender 

FROM Members as m1
JOIN Members as m2
ON m1.recommendedby = m2.memid

UNION 

SELECT m3.surname, m3.firstname, m3.recommendedby as recommender
FROM Members as m3
WHERE m3.recommendedby = '' --didn't recognize ' '  or '' as NULL

ORDER BY m1.surname ASC, m1.firstname ASC;

/* Q12: Find the facilities with their usage by member, but not guests */
SELECT f.name as facility,
m.firstname||' '||m.surname as name,
tbl1.usage*0.5 as usage

FROM(
    SELECT sum(b.slots) as usage, b.memid, b.facid
    FROM Bookings as b
    WHERE b.memid !=0
    GROUP BY b.facid, b.memid
    ) as tbl1

JOIN Facilities as f
ON tbl1.facid = f.facid
JOIN Members as m
ON tbl1.memid = m.memid

ORDER BY facility, name;


/* Q13: Find the facilities usage by month, but not guests */
SELECT f.name, tbl1.month, tbl1.use_hrs *0.5 as usage

FROM (
    SELECT strftime('%m', b.starttime) as month, 
    b.facid, 
    sum(b.slots) as use_hrs 
    FROM Bookings as b
    WHERE b.memid != 0
    GROUP BY b.facid, month
    ) as tbl1
    
JOIN Facilities as f
ON tbl1.facid = f.facid


