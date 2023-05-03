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
    account_no SERIAL PRIMARY KEY,
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
    account_no INT NOT NULL,
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
    cust_phoneno INT check (cust_phoneno >= 1000000000 AND cust_phoneno <= 9999999999),
    account_no INT NOT NULL,
    CONSTRAINT account_fk FOREIGN KEY (account_no)
    REFERENCES account (account_no)
);
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
CREATE TABLE Transaction
(
    Transaction_id SERIAL PRIMARY KEY,
    sender_id INT NOT NULL,
    reciever_id INT NOT NULL,
    payment_date DATE,
    payment_method VARCHAR(25) check(payment_method = 'card' or payment_method = 'cash'),
    CONSTRAINT sender FOREIGN KEY (sender_id)
    REFERENCES customer (cust_id),
    CONSTRAINT reciever FOREIGN KEY (reciever_id)
    REFERENCES customer (cust_id)
);
create table login(
   username varchar(100) primary key,
   id int ,
   password varchar(100) not null

   
);

--roles for customer--not checked
CREATE OR REPLACE FUNCTION create_view_cust_details(uname VARCHAR(100), pword VARCHAR(100))
RETURNS void
AS $create_view_cust_details$
DECLARE
    log_id INT;
    c_name VARCHAR(100);
BEGIN
      IF EXISTS (SELECT id FROM login WHERE username = uname AND password = pword) THEN
       SELECT id INTO log_id FROM login WHERE username = uname AND password = pword;
       EXECUTE 'CREATE OR REPLACE VIEW customer_view AS (SELECT cust_name, cust_address,  cust_phoneno FROM (customer NATURAL JOIN customer_phoneno) WHERE customer.id = '||log_id||')';
       SELECT cust_name INTO c_name FROM customer WHERE id = log_id;
       EXECUTE 'GRANT SELECT ON customer_view TO "'||c_name||'"';
       RAISE NOTICE 'Temporary view called "customer_view" for customer has been created!';
    ELSE
       RAISE NOTICE 'Customer does not exist in database. Check username and password!';
    END IF;
END;
$create_view_cust_details$ LANGUAGE plpgsql
SECURITY DEFINER;
-- function
CREATE OR REPLACE FUNCTION view_balance(id int)
RETURNS numeric(12,3)
AS $$
DECLARE
   temp_balance numeric(12,3);
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
   
  --views
  
CREATE VIEW loan_payment AS 
SELECT loan.loan_id, payment.loan_id, loan.amount AS amount
FROM loan
JOIN payment ON loan.loan_id = payment.loan_id

---------
WHERE loan.amount >= 10000;
create VIEW loan_account
(
    select account.account_no,account.amount,loan.amount as lamount
    from loan ,account
    where account.account_no=loan.account_no
);

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
 
 



        
