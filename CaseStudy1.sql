CREATE DATABASE `CaseStudy_#1`;
use `CaseStudy_#1`;

SET NAMES utf8 ;
SET character_set_client = utf8mb4 ;
SET FOREIGN_KEY_CHECKS=0;

CREATE TABLE `menu` (
  `product_id` tinyint(4) NOT NULL AUTO_INCREMENT ,
  `product_name` VARCHAR(5),
  `price` INTEGER,
  primary key (`product_id`)
)ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO `menu`(`product_id`,`product_name`,`price`)
 value(1,'sushi',10),
 (2,'curry',15),
 (3,'ramen',12);
 
CREATE TABLE `members` (
  `customer_id` VARCHAR(1),
  `join_date` TIMESTAMP,
  primary key (`customer_id`)
)ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

 INSERT INTO `members`(`customer_id`,`join_date`)
 value('A','2021-01-07'),
 ('B','2021-01-09');
 
 CREATE TABLE `sales` (
  `customer_id` VARCHAR(1),
  `order_date` DATE,
  `product_id` tinyint(4),
  KEY `fk_customer_id_idx` (`customer_id`),
  KEY `fk_product_id_idx` (`product_id`),
  CONSTRAINT `fk_customer_client` FOREIGN KEY (`customer_id`) REFERENCES `members` (`customer_id`) ON UPDATE CASCADE,
  CONSTRAINT `fk_product_invoice` FOREIGN KEY (`product_id`) REFERENCES `menu` (`product_id`) ON UPDATE CASCADE
)ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

insert into `sales`(`customer_id`,`order_date`,`product_id`)
value ('A','2021-01-01',1),
('A','2021-01-01',2),
('A','2021-01-07',2),
('A','2021-01-10',3),
('A','2021-01-11',3),
('A','2021-01-11',3),
('B','2021-01-01',2),
('B','2021-01-02',2),
('B','2021-01-04',1),
('B','2021-01-11',1),
('B','2021-01-16',3),
('B','2021-02-01',3),
('C','2021-01-01',3),
('C','2021-01-01',3),
 ('C','2021-01-07',3);
 
