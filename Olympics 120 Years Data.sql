/****** Script for SelectTopNRows command from SSMS  ******/

--Find Total No of Olympics Games held--
		SELECT COUNT(DISTINCT Games) AS Total_Olympics_Games
	 FROM [PortfolioProject].[dbo].[OLYMPICS_HISTORY]
  
  --Olympics Games held till now--
	SELECT DISTINCT Games, Year, Season, City
  FROM [PortfolioProject].[dbo].[OLYMPICS_HISTORY]
  ORDER BY Year;

  --Total No of Nations who participaited in each Olympics_Games--
		SELECT Year,Games,COUNT(DISTINCT(region))
	FROM OLYMPICS_HISTORY INNER JOIN OLYMPICS_HISTORY_NOC_REGIONS
	ON OLYMPICS_HISTORY.NOC = OLYMPICS_HISTORY_NOC_REGIONS.NOC
	GROUP BY Year,Games

----------------------------------------------------------------------------

		WITH All_Countries AS
	(SELECT  Games, nr.region
	FROM [PortfolioProject].[dbo].[OLYMPICS_HISTORY] oh
	JOIN [PortfolioProject].[dbo].[OLYMPICS_HISTORY_NOC_REGIONS] nr ON nr.NOC = oh.NOC
	GROUP BY Games, nr.region)
	SELECT Games, COUNT(1) AS Total_Countries
	FROM All_Countries
	GROUP BY Games
	ORDER BY Games;


	 SELECT Year,Games,COUNT(DISTINCT(region))
	FROM OLYMPICS_HISTORY INNER JOIN OLYMPICS_HISTORY_NOC_REGIONS
	ON OLYMPICS_HISTORY.NOC = OLYMPICS_HISTORY_NOC_REGIONS.NOC
	GROUP BY Year,Games

  --Olympics_Games with the highest and lowest participation of countries--
   WITH All_Countries AS
  (SELECT  Games, nr.region
  FROM [PortfolioProject].[dbo].[OLYMPICS_HISTORY] oh
  JOIN [PortfolioProject].[dbo].[OLYMPICS_HISTORY_NOC_REGIONS] nr ON nr.NOC = oh.NOC
  GROUP BY Games, nr.region
  ), Total_Countries AS
  (
  SELECT Games, COUNT(1) AS Total_Countries
  FROM All_Countries
  GROUP BY Games
  )
    SELECT DISTINCT
      CONCAT(FIRST_VALUE(Games) OVER(ORDER BY Total_Countries)
      , ' - '
      , FIRST_VALUE(Total_Countries) OVER(ORDER BY Total_Countries)) AS Lowest_Countries,
      CONCAT(first_value(Games) OVER(ORDER BY Total_Countries DESC)
      , ' - '
      , FIRST_VALUE(total_countries) OVER(ORDER BY total_countries DESC)) AS Highest_Countries
      FROM Total_Countries
      ORDER BY 1;
	  
--Which nation has participated in all the Olympics_Games?--
		SELECT nr.region,Count(DISTINCT Games) 
	FROM OLYMPICS_HISTORY oh
	INNER JOIN OLYMPICS_HISTORY_NOC_REGIONS nr
	ON oh.NOC = nr.NOC
	GROUP BY region
	HAVING Count(DISTINCT Games) = (SELECT COUNT(DISTINCT Games) FROM OLYMPICS_HISTORY oh);

-----------------------------------------------------------------------------------
  WITH Total_Games AS
              (SELECT COUNT(DISTINCT Games) AS Total_Games
              FROM OLYMPICS_HISTORY oh),
          Countries AS
              (SELECT Games, nr.region AS Country
              FROM OLYMPICS_HISTORY oh
              JOIN OLYMPICS_HISTORY_NOC_REGIONS nr ON nr.noc=oh.noc
              GROUP BY games, nr.region),
          Countries_Participated AS
              (SELECT country, COUNT(1) AS Total_Participated_Games
              FROM countries
              GROUP BY Country)
      SELECT cp.*
      FROM Countries_Participated cp
      JOIN Total_Games tg ON tg.Total_Games = cp.Total_Participated_Games
      ORDER BY 1;

	  --Display list of all sports which have been part of every olympics.--
		SELECT DISTINCT Sport, COUNT(DISTINCT Games) from OLYMPICS_HISTORY
	where Season = 'Summer'
	Group by Sport 
	HAVING COUNT(DISTINCT Games) = (SELECT COUNT(DISTINCT Games) FROM OLYMPICS_HISTORY where Season='Summer')

----------------------------------------------------------------------------------------------------------

  WITH t1 AS
          	(SELECT COUNT(DISTINCT Games) AS Total_Games
          	FROM OLYMPICS_HISTORY WHERE season = 'Summer'),
          t2 AS
          	(SELECT DISTINCT games, sport
          	FROM OLYMPICS_HISTORY WHERE season = 'Summer'),
          t3 AS
          	(SELECT sport, COUNT(1) as No_of_Games
          	FROM t2
          	GROUP BY sport)
      SELECT *
      FROM t3
      JOIN t1 ON t1.Total_Games = t3.No_of_Games;

	  --The sport which were just played once in all of olympics.--
	SELECT Sub.Sport,COUNT(Sub.Sport) FROM 
	(SELECT DISTINCT Sport, Year FROM OLYMPICS_HISTORY) Sub
	GROUP BY Sub.Sport
	Having COUNT(Sub.Sport) = 1

--------------------------------------------------------------------------------------------------

		WITH t1 AS
          	(SELECT DISTINCT games, sport
          	from OLYMPICS_HISTORY),
          t2 AS
          	(SELECT sport, count(1) AS No_of_Games
          	FROM t1
          	GROUP BY sport)
      SELECT t2.*, t1.games
      FROM t2
      JOIN t1 ON t1.sport = t2.sport
      WHERE t2.No_of_Games = 1

--Total no of sports played in each Olympics_Games.--
		SELECT DISTINCT Games,COUNT(DISTINCT Sport) AS No_of_Sports FROM OLYMPICS_HISTORY
	GROUP BY Games
	ORDER BY No_of_Sports DESC

----------------------------------------------------------------------------------------------

	  WITH t1 AS
          	(SELECT DISTINCT games, sport
          	from OLYMPICS_HISTORY),
          t2 AS
          	(SELECT Games, count(1) AS No_of_Sports
          	FROM t1
          	GROUP BY Games)
      SELECT * FROM t2
     ORDER BY No_of_Sports DESC;

--Oldest athletes to win a gold medal at the olympics.--
		SELECT Name, Age
	FROM (SELECT *, DENSE_RANK() OVER(ORDER BY age DESC) AS RNK
	FROM OLYMPICS_HISTORY
	WHERE medal = 'Gold' )sub
	WHERE RNK = 1

	--------------------------------------------------------------------------------------------
	   WITH temp AS
            (SELECT name,sex,CAST(--CASE WHEN age = 'NA' THEN 0 ELSE CAST-- 
			(age as int) END AS int) AS age
              ,team,games,city,sport, event, medal
            FROM OLYMPICS_HISTORY),
        Ranking AS
            (SELECT *, RANK() OVER( ORDER BY age DESC) AS RNK
            FROM temp
            WHERE medal='Gold')
		SELECT *
		FROM Ranking
		 WHERE RNK = 1;
---------------------------------------------------------------------------------------
--Get the ratio of male and female participants in Olympics_Games--

		With t1 (div)
	AS(
	SELECT CAST (sub.count_male AS float) / CAST(sub.count_female AS float) AS div
	FROM (SELECT COUNT(DISTINCT Games) AS count_games,
           SUM(CASE WHEN Sex = 'M' THEN 1 ELSE 0 END) AS count_male,
		   SUM(CASE WHEN Sex = 'F' THEN 1 ELSE 0 END) AS count_female
       FROM OLYMPICS_HISTORY) sub)

		SELECT CONCAT ('1 : ', round(div,2)) AS Ratio_Gender 
	FROM t1

	--Top 5 athletes who have won the most gold medals.--

With t1 AS
	(SELECT name, COUNT(1) AS Total_Medals
	FROM OLYMPICS_HISTORY
	WHERE medal = 'Gold'
	GROUP BY name
	--ORDER BY COUNT(1) DESC--
	),
t2 AS
(SELECT *, DENSE_RANK() OVER (ORDER BY Total_Medals DESC) AS RNK
FROM t1)
SELECT * FROM t2
WHERE RNK <= 5
------------------------------------------------------------------------------------------

--List down the  total gold, silver and bronze medals won by each country--

SELECT region, [Gold], [Silver], [Bronze]
FROM
(
    SELECT games, medal, region
    FROM OLYMPICS_HISTORY OH
    INNER JOIN OLYMPICS_HISTORY_NOC_REGIONS ON OH.NOC = OLYMPICS_HISTORY_NOC_REGIONS.NOC
) as source
PIVOT
(
    COUNT(medal)
    FOR medal IN ([Gold], [Silver], [Bronze])
) as pvt
GROUP BY region, [Gold], [Silver], [Bronze]
HAVING [Gold] + [Silver] + [Bronze] > 0
