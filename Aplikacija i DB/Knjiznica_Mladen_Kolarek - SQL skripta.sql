-------------------------------------------------
--     Seminarski zadatak DBA - Algebra        --
--    Skripta za kreiranje baze podataka       --
--                                             --
-- Kreirao: Mladen Kolarek                     --
-- Datum: 23.5.2023.                           --
-------------------------------------------------
-- Ažurirao:                                   --
-- Datum:                                      --
-------------------------------------------------

USE master
GO

--                                             --
--        Kreiranje baze podataka              --
--                                             --

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'Knjiznica')
	BEGIN
		ALTER DATABASE [Knjiznica] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
		DROP DATABASE Knjiznica
	END
GO

CREATE DATABASE [Knjiznica]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'Knjiznica', FILENAME = N'D:\SQLServer\SQL_Data\Knjiznica.mdf' , SIZE = 8192KB , FILEGROWTH = 65536KB )           -- Upisati putanju do MDF datoteke
 LOG ON 
( NAME = N'Knjiznica_log', FILENAME = N'D:\SQLServer\SQL_Data\Knjiznica_log.ldf' , SIZE = 8192KB , FILEGROWTH = 65536KB )   -- Upisati putanju do LDF datoteke
 COLLATE Croatian_100_CI_AS
GO
ALTER DATABASE [Knjiznica] SET COMPATIBILITY_LEVEL = 150
GO
ALTER DATABASE [Knjiznica] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [Knjiznica] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [Knjiznica] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [Knjiznica] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [Knjiznica] SET ARITHABORT OFF 
GO
ALTER DATABASE [Knjiznica] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [Knjiznica] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [Knjiznica] SET AUTO_CREATE_STATISTICS ON(INCREMENTAL = OFF)
GO
ALTER DATABASE [Knjiznica] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [Knjiznica] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [Knjiznica] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [Knjiznica] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [Knjiznica] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [Knjiznica] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [Knjiznica] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [Knjiznica] SET  DISABLE_BROKER 
GO
ALTER DATABASE [Knjiznica] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [Knjiznica] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [Knjiznica] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [Knjiznica] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [Knjiznica] SET  READ_WRITE 
GO
ALTER DATABASE [Knjiznica] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [Knjiznica] SET  MULTI_USER 
GO
ALTER DATABASE [Knjiznica] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [Knjiznica] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO
ALTER DATABASE [Knjiznica] SET DELAYED_DURABILITY = DISABLED 
GO
USE [Knjiznica]
GO
ALTER DATABASE SCOPED CONFIGURATION SET LEGACY_CARDINALITY_ESTIMATION = Off;
GO
ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET LEGACY_CARDINALITY_ESTIMATION = Primary;
GO
ALTER DATABASE SCOPED CONFIGURATION SET MAXDOP = 0;
GO
ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET MAXDOP = PRIMARY;
GO
ALTER DATABASE SCOPED CONFIGURATION SET PARAMETER_SNIFFING = On;
GO
ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET PARAMETER_SNIFFING = Primary;
GO
ALTER DATABASE SCOPED CONFIGURATION SET QUERY_OPTIMIZER_HOTFIXES = Off;
GO
ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET QUERY_OPTIMIZER_HOTFIXES = Primary;
GO
USE [Knjiznica]
GO
IF NOT EXISTS (SELECT name FROM sys.filegroups WHERE is_default=1 AND name = N'PRIMARY') ALTER DATABASE [Knjiznica] MODIFY FILEGROUP [PRIMARY] DEFAULT
GO



--                                             --
--           Kreiranje tablica                 --
--                                             --

USE Knjiznica
GO


CREATE TABLE dbo.Clan (
IDClan				int IDENTITY(1,1) NOT NULL,
ClanskiBroj			int NOT NULL,
DatumUclanjenja		datetime NOT NULL,
Ime					nvarchar(50) NOT NULL,
Prezime				nvarchar(100) NOT NULL,
OIB					char(11) NOT NULL,
DatumRodjenja		datetime NULL,
AdresaStanovanja	nvarchar(255) NULL,
MjestoStanovanja	nvarchar(255) NULL,
Telefon				nvarchar(25) NULL
CONSTRAINT PK_Clan PRIMARY KEY (IDCLAN),
CONSTRAINT UQ_ClanskiBroj UNIQUE (ClanskiBroj),
CONSTRAINT UQ_OIB UNIQUE (OIB),
CONSTRAINT CHK_DatumUclanjenja CHECK (DatumUclanjenja >= DatumRodjenja)
)
GO


CREATE TABLE dbo.Knjiga (
IDKnjiga			int IDENTITY(1,1) NOT NULL,
KataloskiBroj		int NOT NULL,
Naslov				nvarchar(255) NOT NULL,
PisacIme			nvarchar(50) NULL,
PisacPrezime		nvarchar(100) NULL,
GodinaIzdanja		smallint NULL
CONSTRAINT PK_Knjiga PRIMARY KEY (IDKnjiga),
CONSTRAINT UQ_KataloskiBroj UNIQUE (KataloskiBroj)
)
GO


CREATE TABLE dbo.Posudba (
IDPosudba			int IDENTITY(1,1) NOT NULL,
IDClan				int NOT NULL,
IDKnjiga			int NOT NULL,
DatumPosudbe		datetime NOT NULL DEFAULT(GETDATE()),
DatumVracanja		datetime NULL,
Napomena			nvarchar(2000) NULL
CONSTRAINT PK_IDPosudba PRIMARY KEY (IDPosudba),
CONSTRAINT FK_Clan FOREIGN KEY (IDClan) REFERENCES Clan(IDClan),
CONSTRAINT FK_Knjiga FOREIGN KEY (IDKnjiga) REFERENCES Knjiga(IDKnjiga),
CONSTRAINT UQ_IDClanIDKnjgaDatumPosudbe UNIQUE (IDClan,IDKnjiga,DatumPosudbe),
CONSTRAINT CHK_DatumVracanja CHECK (DatumVracanja >= DatumPosudbe)
)
GO





--                                             --
--      Pogled - popis svih slobodnih          --
--      knjiga u knjižnici za posudbu          --
--                                             --

USE Knjiznica
GO

CREATE VIEW [dbo].[vw_slobodneKnjige] 
AS
	SELECT DISTINCT
		k.IDKnjiga,
		k.KataloskiBroj,
		k.Naslov,
		k.PisacIme,
		k.PisacPrezime,
		k.GodinaIzdanja
		FROM dbo.Knjiga k
		LEFT OUTER JOIN dbo.Posudba p ON k.IDKnjiga = p.IDKnjiga
		WHERE p.DatumPosudbe IS NULL OR (p.DatumPosudbe IS NOT NULL AND p.DatumVracanja IS NOT NULL)
	EXCEPT
	SELECT DISTINCT
		k.IDKnjiga,
		k.KataloskiBroj,
		k.Naslov,
		k.PisacIme,
		k.PisacPrezime,
		k.GodinaIzdanja
		FROM dbo.Knjiga k
		JOIN dbo.Posudba p ON k.IDKnjiga = p.IDKnjiga
		WHERE p.DatumVracanja IS NULL
GO
-- SELECT * FROM dbo.vw_slobodneKnjige




--                                             --
--      Pogled - popis svih slobodnih          --
--      knjiga u knjižnici za posudbu          --
--     proširen s podacima zadnje posudbe      --
--       i koji èlan je zadnji posudio         --
--                                             --

USE Knjiznica
GO

CREATE VIEW dbo.vw_slobodneKnjigeZadnjaPosudba 
AS
SELECT
	IDKnjiga,
	KataloskiBroj,
	Naslov,
	PisacIme,
	PisacPrezime,
	GodinaIzdanja,
	DatumPosudbe,
	DatumVracanja,
	ClanskiBroj,
	Ime,
	Prezime
	FROM (
			SELECT 
				k.IDKnjiga,
				k.KataloskiBroj,
				k.Naslov,
				k.PisacIme,
				k.PisacPrezime,
				k.GodinaIzdanja,
				p.DatumPosudbe,
				p.DatumVracanja,
				c.ClanskiBroj,
				c.Ime,
				c.Prezime,
				Rank() OVER (PARTITION BY k.Naslov ORDER BY p.DatumVracanja DESC) RankOrder
				FROM dbo.Knjiga k
				LEFT OUTER JOIN dbo.Posudba p ON k.IDKnjiga = p.IDKnjiga
				LEFT OUTER JOIN dbo.Clan c ON p.IDClan = c.IDClan
				WHERE k.IDKnjiga IN (SELECT IDKnjiga FROM dbo.vw_slobodneKnjige)
			) T
WHERE RankOrder = 1
GO
--SELECT * FROM dbo.vw_slobodneKnjigeZadnjaPosudba 



--                                             --
--      Pogled - popis svih posuðenih          --
--      knjiga u knjižnici prošireno s         --
--      podacima aktivne posudbe i èlanom      --
--          koji je posudio knjigu             --
--                                             --
USE Knjiznica
GO


CREATE VIEW dbo.vw_posudjeneKnjigePosudbaClanovi 
AS
SELECT 
	p.IDPosudba,
	k.IDKnjiga,
	k.KataloskiBroj,
	k.Naslov,
	k.PisacIme,
	k.PisacPrezime,
	k.GodinaIzdanja,
	p.DatumPosudbe,
	p.DatumVracanja,
	c.ClanskiBroj,
	c.Ime,
	c.Prezime
	FROM dbo.Knjiga k
	JOIN dbo.Posudba p ON k.IDKnjiga = p.IDKnjiga
	JOIN dbo.Clan c ON p.IDClan = c.IDClan
	WHERE p.DatumVracanja IS NULL

GO
--SELECT * FROM dbo.vw_posudjeneKnjigePosudbaClanovi 




--                                             --
--   Storana procedura - èlanovi koji nikada   --
--      nisu posudili niti jednu knjigu        --
--        kopiraju se u novu tablicu,          --
--         a iz stare tablice se brišu         --
--                                             --

USE Knjiznica
GO

CREATE PROCEDURE dbo.sp_Neaktivni
AS
	BEGIN
		IF NOT EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Neaktivni')
			BEGIN		
				SELECT
					c.IDClan,
					c.ClanskiBroj,
					c.DatumUclanjenja,
					c.Ime,
					c.Prezime,
					c.OIB,
					c.DatumRodjenja,
					c.AdresaStanovanja,
					c.MjestoStanovanja,
					c.Telefon,
					GETDATE() AS DatumNeaktivno,
					'Nije nikada posudio knjigu!' AS RazlogNeaktivnosti
					INTO dbo.Neaktivni
					FROM dbo.Clan c
					LEFT OUTER JOIN dbo.Posudba p ON c.IDClan = p.IDClan
					WHERE p.IDClan IS NULL		
			END
		ELSE
			BEGIN
				INSERT INTO dbo.Neaktivni 
					SELECT
						c.IDClan,
						c.ClanskiBroj,
						c.DatumUclanjenja,
						c.Ime,
						c.Prezime,
						c.OIB,
						c.DatumRodjenja,
						c.AdresaStanovanja,
						c.MjestoStanovanja,
						c.Telefon,
						GETDATE() AS DatumNeaktivno,
						'Nije nikada posudio knjigu!' AS RazlogNeaktivnosti
					FROM dbo.Clan c
					LEFT OUTER JOIN dbo.Posudba p ON c.IDClan = p.IDClan
					WHERE p.IDClan IS NULL				
			END

		DELETE FROM dbo.Clan
		WHERE IDClan IN (SELECT IDClan FROM dbo.Neaktivni)
	END
GO
-- EXEC dbo.sp_Neaktivni
-- SELECT * FROM dbo.Neaktivni


--                                             --
--   Trigger - podaci u tablici se ne smiju    --
--                 brisati                     --
--                                             --

USE Knjiznica
GO

CREATE TRIGGER dbo.tr_NEbrisi
ON dbo.Posudba
INSTEAD OF DELETE
AS
	RAISERROR('Brisanje podataka nije dozvoljeno!',14,1)
	ROLLBACK TRANSACTION
GO
-- DELETE FROM dbo.Posudba


--                                             --
--    Trigger - ne može se posuditi aktivno    --
--             posuðena knjiga                 --
--                                             --

USE Knjiznica
GO

CREATE TRIGGER dbo.tr_KnjigaPosudjena
ON dbo.Posudba
INSTEAD OF INSERT
AS
	IF EXISTS (SELECT IDKnjiga FROM Posudba WHERE IDKnjiga = (SELECT IDKnjiga FROM INSERTED) AND DatumVracanja IS NULL)
		BEGIN
			RAISERROR('Knjiga nije vraæena i ne može biti posuðena!',14,1)
			ROLLBACK TRANSACTION
		END
	ELSE
		BEGIN
			INSERT INTO Posudba SELECT IDClan,IDKnjiga,DatumPosudbe,DatumVracanja,Napomena FROM INSERTED
		END
GO




--                                             --
--        Punjenje testnih podataka            --
--                                             --


USE Knjiznica
GO

INSERT INTO dbo.Clan VALUES (101,'2011-06-04','Ana','Aniæ','12345678901','1973-09-05','Domaæinoviæeva 13','Zagreb','+385996927326')
INSERT INTO dbo.Clan VALUES (102,'2012-01-14','Bruno','Bruniæ','98765432109','1973-04-12','Gornja Stubica 15A','Gornja Stubica','+385991234567')
INSERT INTO dbo.Clan VALUES (103,'2015-02-24','Duško','Duškiæ','87654321098','1972-04-13','Trg Ivana Meštroviæa 14','Zagreb','+385999876543')
INSERT INTO dbo.Clan VALUES (104,'2021-03-15','Grga','Grgiæ','00000000001','1965-12-10','Šubiæeva 16','Zagreb','+385916001698')
INSERT INTO dbo.Clan VALUES (105,'2014-02-05','Hrvoje','Hrvojiæ','99999999991','1975-10-01','Velikogorièka 105','Velika Gorica','+385991001202')
INSERT INTO dbo.Clan VALUES (106,'2019-11-01','Ivo','Iviæ','23456789012','1980-06-30','Kombolova 16','Zagreb','+385916951517')
INSERT INTO dbo.Clan VALUES (107,'2020-05-06','Kristijan','Kikiæ','56789432105','1982-01-21','Savica 18','Zagreb','+385921005658')
INSERT INTO dbo.Clan VALUES (108,'2020-05-06','Miro','Miriæ','89012345678','1980-10-14',NULL,'Zagreb',NULL)
INSERT INTO dbo.Clan VALUES (109,'2020-05-06','Pero','Periæ','67890123456','1991-02-15','Ulica Grada Mainza 162','Zagreb','+385915454102')
INSERT INTO dbo.Clan VALUES (110,'2022-04-24','Zoran','Zoriæ','34567890123','1974-08-12','Vrapèe 55','Zagreb',NULL)
GO
-- SELECT * FROM Clan

INSERT INTO dbo.Knjiga VALUES (1001,'Bajke','Hans Christian', 'Andersen',1835)
INSERT INTO dbo.Knjiga VALUES (1002,'Božanstvena komedija','Dante', 'Alighieri',1265)
INSERT INTO dbo.Knjiga VALUES (1003,'Otac Goriot','Honoré', 'de Balzac',1835)
INSERT INTO dbo.Knjiga VALUES (1004,'Molloy, Malone umire, The Unnamable, trilogija','Samuel','Beckett',1951)
INSERT INTO dbo.Knjiga VALUES (1005,'Dekameron','Giovanni','Boccaccio',1349)
INSERT INTO dbo.Knjiga VALUES (1006,'Orkanski visovi','Emily','Brontë',1847)
INSERT INTO dbo.Knjiga VALUES (1007,'Don Kihot','Miguel','de Cervantes',1605)
INSERT INTO dbo.Knjiga VALUES (1008,'Canterburyjske prièe','Geoffrey','Chaucer',1300)
INSERT INTO dbo.Knjiga VALUES (1009,'Prièe','Anton','Èehovn',1886)
INSERT INTO dbo.Knjiga VALUES (1010,'Stranac','Albert','Camus',1942)
GO
-- SELECT * FROM Knjiga

INSERT INTO dbo.Posudba VALUES ((SELECT IDClan FROM dbo.Clan WHERE ClanskiBroj=101),(SELECT IDKnjiga FROM dbo.Knjiga WHERE Naslov='Božanstvena komedija'),'2023-01-12','2023-01-15',NULL)
INSERT INTO dbo.Posudba VALUES ((SELECT IDClan FROM dbo.Clan WHERE ClanskiBroj=101),(SELECT IDKnjiga FROM dbo.Knjiga WHERE Naslov='Otac Goriot'),'2023-01-12','2023-01-15',NULL)
INSERT INTO dbo.Posudba VALUES ((SELECT IDClan FROM dbo.Clan WHERE ClanskiBroj=101),(SELECT IDKnjiga FROM dbo.Knjiga WHERE Naslov='Don Kihot'),'2023-04-20','2023-04-21',NULL)
INSERT INTO dbo.Posudba VALUES ((SELECT IDClan FROM dbo.Clan WHERE ClanskiBroj=109),(SELECT IDKnjiga FROM dbo.Knjiga WHERE Naslov='Dekameron'),'2021-05-01','2021-10-15',NULL)
INSERT INTO dbo.Posudba VALUES ((SELECT IDClan FROM dbo.Clan WHERE ClanskiBroj=109),(SELECT IDKnjiga FROM dbo.Knjiga WHERE Naslov='Stranac'),'2023-03-21',NULL,NULL)
INSERT INTO dbo.Posudba VALUES ((SELECT IDClan FROM dbo.Clan WHERE ClanskiBroj=105),(SELECT IDKnjiga FROM dbo.Knjiga WHERE Naslov='Otac Goriot'),'2022-04-01','2022-05-01',NULL)
INSERT INTO dbo.Posudba VALUES ((SELECT IDClan FROM dbo.Clan WHERE ClanskiBroj=105),(SELECT IDKnjiga FROM dbo.Knjiga WHERE Naslov='Dekameron'),'2022-04-01','2022-05-01',NULL)
INSERT INTO dbo.Posudba VALUES ((SELECT IDClan FROM dbo.Clan WHERE ClanskiBroj=105),(SELECT IDKnjiga FROM dbo.Knjiga WHERE Naslov='Dekameron'),'2023-02-01',NULL,NULL)
INSERT INTO dbo.Posudba VALUES ((SELECT IDClan FROM dbo.Clan WHERE ClanskiBroj=102),(SELECT IDKnjiga FROM dbo.Knjiga WHERE Naslov='Orkanski visovi'),'2023-04-15',NULL,NULL)
INSERT INTO dbo.Posudba VALUES ((SELECT IDClan FROM dbo.Clan WHERE ClanskiBroj=102),(SELECT IDKnjiga FROM dbo.Knjiga WHERE Naslov='Don Kihot'),'2023-04-15',NULL,NULL)
GO
-- SELECT * FROM Posudba






--                                             --
--    User - kreiranje usera i role na bazi    --
--             ivica - Pa$$w0rd                --
--              db_datawriter                  --
--                                             --

USE [master]
GO

IF NOT EXISTS (SELECT loginname FROM sys.syslogins WHERE loginname='ivica') 
	BEGIN
		CREATE LOGIN [ivica] WITH PASSWORD=N'Pa$$w0rd', DEFAULT_DATABASE=[Knjiznica], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
	END


USE [Knjiznica]
GO

CREATE USER [ivica] FOR LOGIN [ivica]
GO

ALTER ROLE [db_datawriter] ADD MEMBER [ivica]
GO




--                                             --
--   Backup - izrada sigurnosne kopije baze    --
--                podataka                     --
--                                             --

-- Upisati putanju do BAK datoteke
BACKUP DATABASE [Knjiznica] TO  DISK = N'D:\SQLServer\SQL_Backup\knjiznica_bkp.bak' WITH  COPY_ONLY, NOFORMAT, NOINIT,  NAME = N'Knjiznica-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO
