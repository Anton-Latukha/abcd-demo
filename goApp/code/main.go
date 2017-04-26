package main

import (
	"os"
	"fmt"
	"time"
	"log"

	"database/sql"						// SQL DB module
	_ "github.com/go-sql-driver/mysql" 	// driver for MySQL, for usage by SQL module
)

func check(err error) { // When !happens
	if err != nil {
		log.Fatal(err)
		panic(err.Error()) // Just for workpiece purpose. Use proper error handling in production.
	}
}

func main() {

	// Create file
	outputFilePath := "/usr/share/nginx/html/index.html" // File of main output
	outputFile, err := os.Create(outputFilePath)
	check(err)
	defer outputFile.Close() // Don't forget to close file

	// Creating DB handler

	/// Connect information
	driverName := "mysql"
	dbTransport := "tcp"
	dbAddress := "mysql"
	dbPort := "3306"
	dbUser := "root"
	dbUserPass := "verysecretpassword"
	dbName := "employees"
	dbAccess := dbUser +
		":" + dbUserPass +
		"@" + dbTransport +
		"(" + dbAddress +
		":" + dbPort + ")" +
		"/" + dbName // Canonical form: [username[:password]@][protocol[(address)]]/dbname[?param1=value1&...&paramN=valueN]

	/// Let's form an object handle for DB

	db, err := sql.Open(driverName, dbAccess)
	defer db.Close() //// Don't forget to close work with DB
	check(err)

	err = db.Ping()

	for err != nil { // Wait for database to get online and validate Data Source Name data and connection:
		fmt.Println("Waiting on a connection to: " + driverName, dbAccess + ".")
		time.Sleep(5000 * time.Millisecond)
		err = db.Ping()
	}


	// Now normal usage of the DB, execute the request

	/// Prepare information for reading data
	dbSelectWhat 	:= "first_name,last_name"
	dbSelectFrom 	:= "employees.employees"
	dbSelectWhere	:= "gender='M' AND birth_date='1965-02-01' AND hire_date>'1990-01-01'"
	dbSelectOrderBy	:= "first_name,last_name"

	dbSelect := "SELECT " + dbSelectWhat + " FROM " + dbSelectFrom + " WHERE " + dbSelectWhere + " ORDER BY " + dbSelectOrderBy + ";"


	/// Queue information
	fmt.Println("Doing SELECT in DB...\n" +
		"=======================\n" +
		"== Secret ansver is: ==\n" +
		"=======================\n")
	dbSelectResult, err := db.Query(dbSelect)
	check(err)

	defer dbSelectResult.Close()

	/// Select was good, I am feeling like to start populating a file
	_ , err = outputFile.WriteString("" +
		"<!DOCTYPE html>\n" +
		"<html>\n" +
		"<body>\n" +
		"<h1>Results of request</h1>" +
		"<table>\n")
	check(err)

	//// Go through rows of received from DB table
	for dbSelectResult.Next() { // next row
		var firstName string
		var lastName string

		err := dbSelectResult.Scan(&firstName, &lastName) // copy row from result of a request to local variables
		///// func (*Row) Scan
		///// func (r *Row) Scan(dest ...interface{}) error
		///// Scan copies the columns from the matched row into the values pointed by dest. See the documentation on Rows.Scan for details.
		///// If more than one row matches the query, Scan uses the first row and discards the rest. If no row matches the query, Scan returns ErrNoRows.
		if err != nil {
			log.Fatal("Crash, extraction unsuccesfull, dbSelectResult.Scan result: firstName: " + firstName + ", lastName: " + lastName)
			log.Fatal(err)
			panic(err.Error()) // Just for workpiece purpose. Should use proper error handling instead of panic in non demo.
		}

		_ , err = outputFile.WriteString("<tr><td>" + firstName + "</td>\t<td>" + lastName + "</td></tr>\n")
		check(err)

		fmt.Println(firstName + " " + lastName)
	}
	if err := dbSelectResult.Err(); err != nil {
		log.Fatal(err)
	}
	fmt.Println("\n=======================\nDB extraction successful!")

	_ , err = outputFile.WriteString("" +
		"</body>\n" +
		"</html>\n")

	fmt.Println("Bonus: Now you can look at this information at http://'this_host_mashine'.\n" +
		"\nP.S.\n" +
		"I am a Go program. I am running inside a Docker container. I am incide separated network.\n" +
		"So it is cruel for you to ask your host IP from me.\n" +
		"So, please, go to http://'this_host_mashine'.")
	check(err)
}
