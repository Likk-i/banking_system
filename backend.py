from flask import Flask,render_template,request,jsonify
import psycopg2

app = Flask(__name__)

@app.route('/') 
def index(): 
   
   return render_template("index.html")
   
   
@app.route('/login', methods=['POST'])
def get_login():
  
   password=request.json['pass']
   name = request.json['name'] 
                     #usermane:password              #database to connect
   connection_db = psycopg2.connect(host="localhost",
    database="banking_systems",
    user="postgres",
    password="postgres")
   cur=connection_db.cursor()
 
   cur.execute("select password from login where id = %s and password= %s",(name,password))
   row=cur.fetchall()
   print(row)
   if(len(row)<=0):
       print("hi this work")
       return {
          'dat':"-1"
       }
   else :
      print("second group")
      return{
         'dat':"1"
      }

@app.route('/employee', methods=['POST'])
def get_employee():#todo add the function this is for implementation purpose
   #still not using any real request  
   id=request.json['name']
   connection_db = psycopg2.connect(host="localhost",
    database="banking_systems",
    user="postgres",
    password="postgres")
   
   customer = [
            {"id": "1", "name": "Project A"},
            {"id": "2", "name": "Project B"},
            {"id": "3", "name": "Project C"},
            {"id": "4", "name": "Project D"},
            {"id": "5", "name": "Project E"},
            {"id": "6", "name": "Project F"},
            {"id": "7", "name": "Project G"},
            {"id": "8", "name": "Project H"},
            {"id": "9", "name": "Project I"},
            {"id": "10", "name": "Project J"},
            {"id": "11", "name": "Project K"}
        ]
  
   return{
        'name':"BabaAradhy", 
        'address': "a_placeno",
        'salary':"cannotbemeasured",
        'branch':"cse",
        'customer':customer,
        'num_cust':len(customer)
      
   } 
     
   
#crat cust ->order should have 
#customer --->


@app.route('/customer_data',methods=['POST'])
def customer_data():

   return {
        'name':"aradhy",
      }


     


if __name__ == "__main__":
    app.run(host="0.0.0.0")
   
   
  
#printing the connection object   
  
   




