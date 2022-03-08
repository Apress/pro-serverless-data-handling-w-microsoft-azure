CREATE SCHEMA staging;

CREATE TABLE staging.ReqResUsers 
(
  Id int not null, 
  Email varchar(100) not null, 
  FirstName varchar(100) not null, 
  LastName varchar(100) not null, 
  AvatarURL varchar(200) not null,
  LoadID uniqueidentifier not null 
)