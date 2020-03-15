
<?php
$connection = mysql_connect("localhost:3307", "root", ""); // Establishing Connection with Server
$db = mysql_select_db("samplelogin", $connection); // Selecting Database from Server
  if(isset($_POST['signin'])){ // Fetching variables of the form which travels in URL
  $ID = $_AUTO_INCRE['ID'];
  $userid = $_POST['userid'];
  $password = $_POST['password'];
  if($userid !='userid'||$password !='password'){
   //Insert Query of SQL
  $query = mysql_query("insert into students(ID, userid, password) values ('NULL', '$userid', '$password')");

   }
  mysql_close($connection); // Closing Connection with Server

?>


<html>
<head>
  <title>Login</title>
  <link rel="stylesheet" href="Login.css">
  <link href='https://fonts.googleapis.com/css?family=Alegreya Sans SC' rel='stylesheet'>
  <link rel="stylesheet" href="path/to/font-awesome/css/font-awesome.min.css">
  <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/font-awesome/4.7.0/css/font-awesome.min.css">
  <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/css/bootstrap.min.css" integrity="sha384-Vkoo8x4CGsO3+Hhxv8T/Q5PaXtkKtu6ug5TOeNV6gBiFeWPGFN9MuhOf23Q9Ifjh" crossorigin="anonymous">
  <meta charset="utf-8">
  <style>
  *{
    margin: 0px;
    padding: 0px;
  }
  body{
    background-image: url(Login.jpg);
    background-size: cover;
    background-attachment: fixed;;
    font-family: cursive;
  }
  ul{
    margin-bottom: 50px;
  }
  ul a{
    font-size:29px;
    color:white;
  }
  ul a:hover{
    text-decoration: none;
    color: gray;
  }
  .label{
    font-size: 20px;
    color: white;
    font-weight: normal;
  }
  .form-control{
    background:transparent;
    border-radius: 0px;
    border: 0px;
    border-bottom: 1px solid #f44c89;
    margin-bottom: 30px;
    font-size: 22px;
    color: white;
    padding: 20px;
  }
  input[type="checkbox"]{
    height: 15px;
    width: 15px;
  }
  small{
    font-size: 19px;
    color: white;
  }
  .btn-info{
    background: #f44c89;
    border: 2px solid #f44c89;
    width: 360px;
    margin-top: 20px;
    font-size: 20px;
    background: transparent;
  }
  .btn-info:hover{
    background: #f44c89;
    border: 2px solid #f44c89;
  }
  .container div.row div.col-md-8 div.row div.col-md-6 div.btn.text-center{
    font-size: 16px;
    margin-top: 20px;
    width: 360px;
    font-size: 20px;
    background-color: #0ABFBC;
  }
  .container div.row div.col-md-8 div.row div.col-md-6 div.btn.text-center:hover{
    background-color: #FC354C;
    border: 2px solid #49a09d;
  }
  .container div.row div.col-md-8 div.row div.col-md-6 div.btn.text-center{
    font-size: 14px;
  }
  .container div.row div.col-md-8 div.row div.col-md-6
  {
    width: 380px;
    height: 477px;
    image-orientation: center;
    overflow: hidden;
  }
  .p{
    text-align: center;
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    color: white;
  }
  </style>
</head>
<body>
  <div class="container">
  <form action="register.php" method="post">
    <div class="row">
        <div class="col-md-2"></div>
        <div class="col-md-8">
            <div class="row" style="margin-top:120px;box-shadow:-1px 1px 50px 10px black;">
              <div class="col-md-6">
                <ul>
                  <a href="#"  style="border-bottom:2px solid #f44c89;padding:10px;">Sign In</a>
                  <a href="#">/Sign Up</a>
                </ul>
                <label class="label control-label">Userid</label>
                <input type="text" class="form-control" name="Userid" placeholder="Userid">
                <label class="label control-label">Password</label>
                <input type="password" class="form-control" name="password" placeholder="Password">
                <input type="checkbox"><small>Remember Me?</small>
               <a href="home.html"><div class="btn btn-info" input value='signin' onclick="location.href='home.html'">Sign In</input></div></a>
               <div class="btn text-center"><a href="#"></a>Forget Password?</div>
              </div>
              <div class="col-md-6" ><img src="loginside.jpg"><div class="p"><p>The Online Ration System provided by the govt of India is sujjesting the whole Indian
              Citizen to register their formal ration details to provide this Facility</p></div>
            </div>
           </div>
          </div>
          <div class="col-md-2"></div>
     </form>
    </div>
</body>
