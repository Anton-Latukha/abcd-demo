#!/bin/sh

echo '<!DOCTYPE html>
<html>
<body>

<h1>Results of an SQL query</h1>
<table>' > /usr/share/nginx/html/index.html

SQL_RESULT=`mysql -u root -pverysecretpassword --execute="SELECT '<tr><td>',first_name,'</td><td>',last_name,'</td></tr>' FROM employees.employees WHERE gender='M' AND birth_date='1965-02-01' AND hire_date>'1990-01-01' ORDER BY first_name,last_name;"`

echo 'From DB, we got: \n'"$SQL_RESULT"
echo "$SQL_RESULT" >> /usr/share/nginx/html/index.html

echo '<table>

</table>

</body>
</html>' >> /usr/share/nginx/html/index.html
