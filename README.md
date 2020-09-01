# inv_payroll-project
⁃ The main goal I always try to achieve is writing easy, understandable, oraganized  and maintainable code.
⁃ This sample shows some of the code I used in the last project. 
  this sample contains the following:
- a Package contains all the required procedures and functions to retrieve the required data from the database
  and to calculate salary for each employee.
⁃ Compound trigger to enforce data integrity to prevent date overlapping, 
  also this included locking the table to prevent data integrity violations.
⁃ Trigger to update items quantity after each insert on inventory transaction table.
⁃ a sample Package to achieve some DML operations on inventory tables which included check quantity
  before any dml operation and this required using select for update to prevent data integrity violations.
⁃ Using external tables to load an old data into the database.
⁃ The required tables and packages to instrument code, log and handle runtime errors.
