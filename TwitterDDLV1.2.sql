-- =============================================-----================================
-- Author:      Vidur Nayyar
-- version 1.2
-- Create date: Jan 8, 2016
-- Description: Creates an external table on the ingested data, 
-- creates views for each hotel, 
-- does sentiment analysis on the whole data and ngrams on the whole data
-- Disclaimer: Code has been inspired by the hortonworks example on hortonworks site
-- Code edited by Vidur Nayyar for Sentiment Analysis Project
-- =============================================-----=================================
-- note when automating the code using oozie remove all the drop tables, they are flagged by --#######DROP TABLE##########

--ADD JAR json-serde-1.1.6-SNAPSHOT-jar-with-dependencies.jar; -- you need to run this command only once, the first time
set hive.support.sql11.reserved.keywords=false;-- important to read jar files

DROP TABLE IF EXISTS tweets_raw; --#######DROP TABLE##########
CREATE EXTERNAL TABLE IF NOT EXISTS tweets_raw (
   id BIGINT,
   created_at STRING,
   source STRING,
   favorited BOOLEAN,
   retweet_count INT,
   retweeted_status STRUCT<
      text:STRING,
      user:STRUCT<screen_name:STRING,name:STRING>>,
   entities STRUCT<
      urls:ARRAY<STRUCT<expanded_url:STRING>>,
      user_mentions:ARRAY<STRUCT<screen_name:STRING,name:STRING>>,
      hashtags:ARRAY<STRUCT<text:STRING>>>,
   text STRING,
   user STRUCT<
      screen_name:STRING,
      name:STRING,
      friends_count:INT,
      followers_count:INT,
      statuses_count:INT,
      verified:BOOLEAN,
      utc_offset:STRING, -- was INT but nulls are strings
      time_zone:STRING>,
   in_reply_to_screen_name STRING,
   year int,
   month int,
   day int,
   hour int
)
ROW FORMAT SERDE 'org.apache.hive.hcatalog.data.JsonSerDe'
-----===============================================================================================
-- this will change to where the data is stored, this will be automated when partitions are created
-----===============================================================================================
LOCATION '/tmp/flume/twitter/hotel/2016/01/08'-- this will change
;



-- create sentiment dictionary
CREATE EXTERNAL TABLE IF NOT EXISTS dictionary (
    type string,
    length int,
    word string,
    pos string,
    stemmed string,
    polarity string
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t' 
STORED AS TEXTFILE
LOCATION '/user/root/TwitterData/dictionary'; -- where you saved the dictionary

CREATE EXTERNAL TABLE IF NOT EXISTS time_zone_map (
    time_zone string,
    country string,
    notes string
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t' 
STORED AS TEXTFILE
LOCATION '/user/root/TwitterData/time_zone_map'; -- where you saved the time_zone_map

DROP VIEW IF EXISTS tweets_simple;--#######DROP TABLE##########

-- Clean up tweets
CREATE VIEW IF NOT EXISTS tweets_simple AS
SELECT
  id,
  --the year needs to be updated every year, I will automate it using the year from the twitter feeds will be done in V1.3
  cast ( from_unixtime( unix_timestamp(concat( '2016', substring(created_at,5,15)), 'yyyy MMM dd hh:mm:ss')) as timestamp) ts, 
  text,
  user.time_zone 
FROM tweets_raw
;

DROP VIEW IF EXISTS tweets_clean;--#######DROP TABLE##########
CREATE VIEW IF NOT EXISTS tweets_clean AS
SELECT
  id,
  ts,
  text,
  m.country 
 FROM tweets_simple t LEFT OUTER JOIN time_zone_map m ON t.time_zone = m.time_zone;

DROP VIEW IF EXISTS l1;--#######DROP TABLE##########
DROP VIEW IF EXISTS l2;--#######DROP TABLE##########
DROP VIEW IF EXISTS l3;--#######DROP TABLE##########
-- Compute sentiment
create view IF NOT EXISTS l1 as select id, words from tweets_raw lateral view explode(sentences(lower(text))) dummy as words;
create view IF NOT EXISTS l2 as select id, word from l1 lateral view explode( words ) dummy as word ;

-- was: select * from l2 left outer join dict d on l2.word = d.word where polarity = 'negative' limit 10;

create view IF NOT EXISTS l3 as select 
    id, 
    l2.word, 
    case d.polarity 
      when  'negative' then -1
      when 'positive' then 1 
      else 0 end as polarity 
 from l2 left outer join dictionary d on l2.word = d.word;
 

 DROP TABLE IF EXISTS tweets_sentiment;--#######DROP TABLE##########
 create table IF NOT EXISTS tweets_sentiment stored as orc as select 
  id, 
  case 
    when sum( polarity ) > 0 then 'positive' 
    when sum( polarity ) < 0 then 'negative'  
    else 'neutral' end as sentiment 
 from l3 group by id;

DROP TABLE IF EXISTS tweetsbi;--#######DROP TABLE##########
-- put everything back together and re-number sentiment
CREATE TABLE IF NOT EXISTS tweetsbi 
STORED AS ORC
AS
SELECT 
  t.*,
  case s.sentiment 
    when 'positive' then 2 
    when 'neutral' then 1 
    when 'negative' then 0 
  end as sentiment  
FROM tweets_clean t LEFT OUTER JOIN tweets_sentiment s on t.id = s.id;
-----===============================================================================================
-----                 -----------------my view------------------
-----===============================================================================================
--         you can change then dependng on the requirements

DROP VIEW marriott;--#######DROP TABLE##########
DROP VIEW holiday;--#######DROP TABLE##########
DROP VIEW days;--#######DROP TABLE##########
DROP VIEW super8;--#######DROP TABLE##########
DROP VIEW quality;--#######DROP TABLE##########
DROP VIEW hampton;--#######DROP TABLE##########
DROP VIEW motel6;--#######DROP TABLE##########
DROP VIEW courtyard; --#######DROP TABLE##########

CREATE VIEW IF NOT EXISTS marriott AS
SELECT * FROM tweets_clean
WHERE lower(text) LIKE "% marriott%" AND ( lower(text) LIKE "%hotel%" OR lower(text) LIKE "%motel%" OR lower(text) LIKE "%inn%" OR lower(text) LIKE "%lodge%" OR lower(text) LIKE "%resort%" OR lower(text) LIKE "%b&b%")

;
CREATE VIEW IF NOT EXISTS holiday AS
SELECT * FROM tweets_clean
WHERE lower(text) LIKE "% holiday%" AND ( lower(text) LIKE "%hotel%" OR lower(text) LIKE "%motel%" OR lower(text) LIKE "%inn%" OR lower(text) LIKE "%lodge%" OR lower(text) LIKE "%resort%" OR lower(text) LIKE "%b&b%")
;
CREATE VIEW IF NOT EXISTS super8 AS
SELECT * FROM tweets_clean
WHERE lower(text) LIKE "% super 8%" AND ( lower(text) LIKE "%hotel%" OR lower(text) LIKE "%motel%" OR lower(text) LIKE "%inn%" OR lower(text) LIKE "%lodge%" OR lower(text) LIKE "%resort%" OR lower(text) LIKE "%b&b%")
;
CREATE VIEW IF NOT EXISTS days AS
SELECT * FROM tweets_clean
WHERE lower(text) LIKE "% days%" AND ( lower(text) LIKE "%hotel%" OR lower(text) LIKE "%motel%" OR lower(text) LIKE "%inn%" OR lower(text) LIKE "%lodge%" OR lower(text) LIKE "%resort%" OR lower(text) LIKE "%b&b%")
;
CREATE VIEW IF NOT EXISTS quality AS
SELECT * FROM tweets_clean
WHERE lower(text) LIKE "% quality%" AND ( lower(text) LIKE "%hotel%" OR lower(text) LIKE "%motel%" OR lower(text) LIKE "%inn%" OR lower(text) LIKE "%lodge%" OR lower(text) LIKE "%resort%" OR lower(text) LIKE "%b&b%")
;
CREATE VIEW IF NOT EXISTS hampton AS
SELECT * FROM tweets_clean
WHERE lower(text) LIKE "% hampton%" AND ( lower(text) LIKE "%hotel%" OR lower(text) LIKE "%motel%" OR lower(text) LIKE "%inn%" OR lower(text) LIKE "%lodge%" OR lower(text) LIKE "%resort%" OR lower(text) LIKE "%b&b%")
;
CREATE VIEW IF NOT EXISTS motel6 AS
SELECT * FROM tweets_clean
WHERE lower(text) LIKE "% motel6%" AND ( lower(text) LIKE "%hotel%" OR lower(text) LIKE "%motel%" OR lower(text) LIKE "%inn%" OR lower(text) LIKE "%lodge%" OR lower(text) LIKE "%resort%" OR lower(text) LIKE "%b&b%")
;
CREATE VIEW IF NOT EXISTS courtyard AS
SELECT * FROM tweets_clean
WHERE lower(text) LIKE "% courtyard%" AND ( lower(text) LIKE "%hotel%" OR lower(text) LIKE "%motel%" OR lower(text) LIKE "%inn%" OR lower(text) LIKE "%lodge%" OR lower(text) LIKE "%resort%" OR lower(text) LIKE "%b&b%")
;
-----===============================================================================================
-----                           ------------------mapreduce started--------------
-----===============================================================================================
-------------------------------------
--      the code below needs to be updated depending on requirements

DROP TABLE IF EXISTS twitter_3grams;--#######DROP TABLE##########
-- context n-gram made readable
set hive.execution.engine = mr;
CREATE TABLE IF NOT EXISTS twitter_3grams
STORED AS RCFile

----------

AS
SELECT year, month, day, hour,ngs-- snippet--,snippet1,snippet2,snippet3 
FROM
( SELECT
     year,
     month,
     day,
     hour,
  context_ngrams(sentences(lower(text)), array("marriott",null,null,null), 100) ngs --here<---
FROM tweets_raw
group by year,month,day, hour 
) tweets_raw
--LATERAL VIEW explode(  ngs  ) ngsTab AS snippet-- ngsTab is random alias => must be there even though not used
;
-----===============================================================================================
--                                        Author Vidur
-----===============================================================================================
