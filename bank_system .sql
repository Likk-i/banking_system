create database banking_system;
-- bank table
CREATE TABLE bank(
    bank_code SERIAL PRIMARY KEY,
    bank_address TEXT NOT NULL,
    bank_name VARCHAR(100) NOT NULL
);

-- branch table
CREATE TABLE branch(
    branch_id SERIAL PRIMARY KEY,
    branch_name VARCHAR(100) NOT NULL,
    branch_address TEXT NOT NULL,
    bank_id INT NOT NULL,
    CONSTRAINT bran_fk FOREIGN KEY (bank_id)
    REFERENCES bank (bank_code)
);

-- employee table
CREATE TABLE employee(
    employee_id SERIAL PRIMARY KEY,
    employee_name VARCHAR(100) NOT NULL,
    emp_address TEXT NOT NULL,
    emp_salary INT NOT NULL check(emp_salary >= 10000 AND emp_salary <= 1000000),
    branch_id INT NOT NULL,
    CONSTRAINT emp_fk FOREIGN KEY (branch_id)
    REFERENCES branch (branch_id)
);

-- account table
CREATE TABLE account(
    account_no BIGINT PRIMARY KEY,
    account_type VARCHAR(25) NOT NULL check(account_type='savings' or account_type = 'salary' or account_type= 'loan'),
    balance FLOAT NOT NULL check (balance >= 500.0),
    branch_id INT NOT NULL,
    CONSTRAINT acc_fk FOREIGN KEY (branch_id)
    REFERENCES branch (branch_id)
);

-- loan table
CREATE TABLE loan(
    loan_id SERIAL PRIMARY KEY,
    loan_type VARCHAR(25) NOT NULL check(loan_type = 'personal' or loan_type = 'business' or loan_type = 'home' or loan_type = 'student' or loan_type = 'automobile'),
    amount FLOAT NOT NULL check(amount >= 1000.0),
    interest_rate FLOAT NOT NULL check(interest_rate >= 3.0 and interest_rate <= 12.5),
    account_no BIGINT NOT NULL,
    branch_id INT NOT NULL,
     CONSTRAINT acc_fk FOREIGN KEY (account_no)
    REFERENCES account (account_no),
    CONSTRAINT branch_fk FOREIGN KEY (branch_id)
    REFERENCES branch (branch_id)
);

-- customer table
CREATE TABLE customer(
    cust_id SERIAL PRIMARY KEY,
    cust_name VARCHAR(100) NOT NULL,
    cust_address TEXT NOT NULL,
    cust_phoneno BIGINT check (cust_phoneno >= 1000000000 AND cust_phoneno <= 9999999999),
    account_no BIGINT NOT NULL,
    
    CONSTRAINT account_fk FOREIGN KEY (account_no)
    REFERENCES account (account_no)
);

--payment table
CREATE TABLE payment
(
    loan_interest int NOT NULL,
    pay_id SERIAL PRIMARY KEY,
    pay_amount INT,
    date_ofpay DATE,
    loan_id INT NOT NULL,
    CONSTRAINT loan_fk FOREIGN KEY (loan_id)
    REFERENCES loan(loan_id)
);

--transaction table
CREATE TABLE Transaction
(
    Transaction_id SERIAL PRIMARY KEY,
    sender_id INT NOT NULL,
    reciever_id INT NOT NULL,
    payment_date DATE,
    amount int ,
    payment_method VARCHAR(25) check(payment_method = 'card' or payment_method = 'cash'),
    CONSTRAINT sender FOREIGN KEY (sender_id)
    REFERENCES customer (cust_id),
    CONSTRAINT reciever FOREIGN KEY (reciever_id)
    REFERENCES customer (cust_id)
);

--login table
create table login(
   username varchar(100) primary key,
   id int ,
   password varchar(100) not null

   
);

--roles for customer--not checked
--new view for customer

$create_view_cust_details$ LANGUAGE plpgsql

CREATE FUNCTION create_customer_view(cust_nam VARCHAR(100))
RETURNS VOID AS $$
BEGIN
   IF EXISTS (SELECT cust_name FROM customer WHERE cust_name = cust_nam) THEN
      EXECUTE 'CREATE OR REPLACE VIEW customer_view AS
      SELECT cust_id, cust_name, cust_address, cust_phoneno, account_no
      FROM customer
      WHERE cust_name = "'|| cust_nam ||'"';
      RAISE NOTICE 'View has been created';
   ELSE 
      RAISE NOTICE 'Customer does not exist';
   END IF;
END;
$$ LANGUAGE plpgsql;
--create a view for emplyee table
CREATE FUNCTION create_employee_view(emp_id INTEGER)
RETURNS VOID AS $$
DECLARE
    temp_balance NUMERIC(12,3);
BEGIN
    IF EXISTS (SELECT employee_id FROM employee WHERE employee_id = emp_id) THEN
        EXECUTE 'CREATE OR REPLACE VIEW employee_customer_view AS
        SELECT e.employee_id, e.employee_name, e.emp_address, e.emp_salary,
               c.cust_id, c.cust_name, c.cust_address, c.cust_phoneno, c.account_no
        FROM employee e
        JOIN customer c ON e.employee_id = c.employee_id
        WHERE e.employee_id = ' || emp_id || ''; 
        RAISE NOTICE 'View has been created';
    ELSE
        RAISE NOTICE 'Employee does not exist';
    END IF;
END;
----- view for loan payment
CREATE VIEW loan_payment AS 
SELECT loan.loan_id, payment.loan_id, loan.amount AS amount
FROM loan
JOIN payment ON loan.loan_id = payment.loan_id
WHERE loan.amount >= 10000;
create VIEW loan_account
(
    select account.account_no,account.amount,loan.amount as lamount
    from loan ,account
    where account.account_no=loan.account_no
);
-- function
CREATE OR REPLACE FUNCTION view_balance(id int)
RETURNS numeric(12,3)
AS $$
DECLARE
   temp_balance numeric(14,2);
BEGIN
    IF EXISTS (SELECT balance FROM account WHERE account_no = id) THEN
        SELECT balance INTO temp_balance FROM account WHERE account_no = id;
        RETURN temp_balance;
    ELSE
        RAISE NOTICE 'Invalid account, check input id';
        RETURN NULL;
    END IF;
END;
$$ LANGUAGE plpgsql;

--payment log function between particular dates
CREATE OR REPLACE FUNCTION show_payment_log(id INT, start_date DATE, end_date DATE, uname VARCHAR(50), pword VARCHAR(50))
RETURNS TABLE (
    payment_amount NUMERIC(12, 2),
    payment_date TIMESTAMP WITHOUT TIME ZONE,
    interest NUMERIC(4, 2)
)
AS $show_payment_log$
BEGIN
    IF EXISTS (SELECT id FROM login WHERE username = uname AND password = pword) THEN
    BEGIN
        IF EXISTS (SELECT loan_id FROM payment WHERE loan_id = id) THEN
           RETURN QUERY
           SELECT pay_amount, pay_date, loan_interest FROM payment
           WHERE loan_id = id AND pay_date BETWEEN start_date AND end_date;
        ELSE
           RAISE NOTICE 'Invalid Loan id';
        END IF;
    END;
    ELSE
        RAISE NOTICE 'Invalid Login';
    END IF;
END;
$show_payment_log$ LANGUAGE plpgsql

--procedure
CREATE OR REPLACE PROCEDURE withdrawAmount(id int,amt NUMERIC(12,3))
language plpgsql
as $$
declare
temp_amt NUMERIC(12,3);
begin 
   if exists (select balance from account where account_no=id)then
          select balance into temp_amt from account where account_no=id;
          IF (temp_amt >= (amt + 500) AND amt <= 10000000) THEN
          BEGIN
            UPDATE account SET balance = balance - amt WHERE account_no = id;
            RAISE NOTICE 'Successfull transaction! Balance amount : %', (temp_amt - amt);
          END;
          ELSE
            RAISE NOTICE 'Insufficient balance in account! Balance amount : %', temp_amt;
          end if;
    else
         RAISE NOTICE 'Account doesnot exist. Check input account number!';
       END IF;
   END;$$;
   
CREATE OR REPLACE FUNCTION check_loan_eligibility(customer_id INT)
RETURNS BOOLEAN AS $$
DECLARE
    total_loan_amount DECIMAL;
    total_loan_count INT;
    eligible BOOLEAN;
BEGIN
    -- Calculate the total loan amount and count for the given customer
    SELECT SUM(amount) INTO total_loan_amount
    FROM Loan
    WHERE loan_id IN (
        SELECT loan_id
        FROM Customer_Loan
        WHERE cust_id = check_loan_eligibility.customer_id
    );

    SELECT COUNT(*) INTO total_loan_count
    FROM Customer_Loan
    WHERE cust_id = check_loan_eligibility.customer_id;

    -- Check eligibility criteria
    IF total_loan_amount < 1000000 AND total_loan_count < 5 THEN
        eligible := TRUE;
    ELSE
        eligible := FALSE;
    END IF;

    RETURN eligible;
END;
$$ LANGUAGE plpgsql;
   
  --views


--roles
CREATE ROLE branch_admin password 'branch_admin';
GRANT ALL ON branch, employee, custozmer, account, account, Transaction, payment, loan TO branch_admin;

CREATE ROLE employee password 'employee';
GRANT ALL ON customer, account, account, Transaction, payment, loan TO employee;

---queries
--finding the name of employee with high salary
select name,branch_id from employee
 where salary>50000;
 --finding last day tracnstion
select cust_name
from Transaction inner join customer
where payment_date>=getdate()-1;
--finding last 5 transaction of a customer
SELECT Transaction_id, sender_id, receiver_id, payment_date, payment_method
FROM Transaction
WHERE sender_id = 123 
ORDER BY payment_date DESC
LIMIT 5;
--finding the total number of customer mannage by a employee
SELECT e.employee_id, e.employee_name, COUNT(c.cust_id) AS total_customers
FROM employee e
JOIN branch b ON e.branch_id = b.branch_id
JOIN account a ON b.branch_id = a.branch_id
JOIN customer c ON a.account_no = c.account_no
WHERE e.employee_id = 123
GROUP BY e.employee_id, e.employee_name;
--name and ammount of loan a person is having
select  cust_name,loan.amount as Amount
from customer inner join loan
where loan.account_no=customer.account_no;
--dummy data insertion and code generation for login okkk
 

      
--dummy data insertion and code generation for login okkk
 
 --trigger to set up login
 CREATE OR REPLACE FUNCTION insert_login_row()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO login (username, password, id)
    VALUES (NEW.cust_name, NEW.password, NEW.cust_id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER customer_trigger
AFTER INSERT ON customer
FOR EACH ROW
EXECUTE FUNCTION insert_login_row();
 --login to password when inserted role and this

      
