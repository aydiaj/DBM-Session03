-- DB3 Session 03, part 1: preserve and validate the Session 02 foundation. Run this entire file in SSMS on the SAME instance as C#.
-- Non-destructive: never drops databases/tables or overwrites existing rows.
-- If this database belongs to another exercise, ask the instructor for a NEW name.
USE master;
GO
IF DB_ID(N'TVET_DBM_Lab01') IS NULL
    EXEC(N'CREATE DATABASE TVET_DBM_Lab01;');
GO
USE TVET_DBM_Lab01;
GO
SET XACT_ABORT ON;
BEGIN TRY
    BEGIN TRANSACTION;

    IF OBJECT_ID(N'dbo.Students') IS NOT NULL AND OBJECT_ID(N'dbo.Students', N'U') IS NULL
        THROW 50001, 'dbo.Students exists but is not a user table. Use a new lab database.', 1;
    IF OBJECT_ID(N'dbo.Courses') IS NOT NULL AND OBJECT_ID(N'dbo.Courses', N'U') IS NULL
        THROW 50001, 'dbo.Courses exists but is not a user table. Use a new lab database.', 1;
    IF OBJECT_ID(N'dbo.Enrollments') IS NOT NULL AND OBJECT_ID(N'dbo.Enrollments', N'U') IS NULL
        THROW 50001, 'dbo.Enrollments exists but is not a user table. Use a new lab database.', 1;

    IF OBJECT_ID(N'dbo.Students', N'U') IS NULL
        CREATE TABLE dbo.Students (
            StudentId INT NOT NULL CONSTRAINT PK_Students PRIMARY KEY,
            FullName NVARCHAR(80) NOT NULL
        );
    IF OBJECT_ID(N'dbo.Courses', N'U') IS NULL
        CREATE TABLE dbo.Courses (
            CourseId INT NOT NULL CONSTRAINT PK_Courses PRIMARY KEY,
            CourseName NVARCHAR(100) NOT NULL,
            CreditHours INT NOT NULL
        );
    -- Validate columns BEFORE creating FKs or seeding any existing tables.
    DECLARE @Expected TABLE (TableName SYSNAME, ColumnName SYSNAME, TypeName SYSNAME, MaxLength SMALLINT);
    INSERT @Expected VALUES
        ('Students','StudentId','int',4), ('Students','FullName','nvarchar',160),
        ('Courses','CourseId','int',4), ('Courses','CourseName','nvarchar',200), ('Courses','CreditHours','int',4);
    IF EXISTS (
        SELECT 1 FROM @Expected e LEFT JOIN sys.columns c
        ON c.object_id = OBJECT_ID(N'dbo.' + e.TableName) AND c.name = e.ColumnName
        WHERE c.column_id IS NULL OR TYPE_NAME(c.user_type_id) <> e.TypeName
          OR c.max_length <> e.MaxLength OR c.is_nullable <> 0 OR c.is_identity <> 0 OR c.is_computed <> 0
    )
        THROW 50002, 'Existing Students/Courses schema is incompatible. Nothing was seeded; use a new lab database.', 1;

    IF OBJECT_ID(N'dbo.Enrollments', N'U') IS NULL
        CREATE TABLE dbo.Enrollments (
            EnrollmentId INT NOT NULL CONSTRAINT PK_Enrollments PRIMARY KEY,
            StudentId INT NOT NULL,
            CourseId INT NOT NULL,
            CONSTRAINT FK_Enrollments_Students FOREIGN KEY(StudentId) REFERENCES dbo.Students(StudentId),
            CONSTRAINT FK_Enrollments_Courses FOREIGN KEY(CourseId) REFERENCES dbo.Courses(CourseId),
            CONSTRAINT UQ_Enrollments UNIQUE(StudentId, CourseId)
        );
    INSERT @Expected VALUES ('Enrollments','EnrollmentId','int',4), ('Enrollments','StudentId','int',4), ('Enrollments','CourseId','int',4);
    IF EXISTS (
        SELECT 1 FROM @Expected e LEFT JOIN sys.columns c
        ON c.object_id = OBJECT_ID(N'dbo.' + e.TableName) AND c.name = e.ColumnName
        WHERE c.column_id IS NULL OR TYPE_NAME(c.user_type_id) <> e.TypeName
          OR c.max_length <> e.MaxLength OR c.is_nullable <> 0 OR c.is_identity <> 0 OR c.is_computed <> 0
    )
        THROW 50003, 'Existing Enrollments schema is incompatible. Use a new lab database.', 1;

    -- Each table must have the expected SINGLE-column primary key.
    IF EXISTS (
        SELECT 1 FROM (VALUES ('Students','StudentId'),('Courses','CourseId'),('Enrollments','EnrollmentId')) e(T,C)
        WHERE NOT EXISTS (
            SELECT 1 FROM sys.indexes i JOIN sys.index_columns ic ON ic.object_id=i.object_id AND ic.index_id=i.index_id
            JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
            WHERE i.object_id=OBJECT_ID(N'dbo.'+e.T) AND i.is_primary_key=1 AND c.name=e.C AND ic.key_ordinal=1
              AND (SELECT COUNT(*) FROM sys.index_columns k WHERE k.object_id=i.object_id AND k.index_id=i.index_id AND k.key_ordinal>0)=1
        )
    ) THROW 50004, 'Expected primary keys are missing or incompatible. Use a new lab database.', 1;

    IF EXISTS (
        SELECT 1 FROM (VALUES ('Students','StudentId'),('Courses','CourseId')) e(T,C)
        WHERE NOT EXISTS (
            SELECT 1 FROM sys.foreign_keys f JOIN sys.foreign_key_columns k ON f.object_id=k.constraint_object_id
            WHERE f.parent_object_id=OBJECT_ID(N'dbo.Enrollments') AND f.referenced_object_id=OBJECT_ID(N'dbo.'+e.T)
              AND COL_NAME(k.parent_object_id,k.parent_column_id)=e.C
              AND COL_NAME(k.referenced_object_id,k.referenced_column_id)=e.C
              AND f.is_disabled=0 AND f.is_not_trusted=0
              AND (SELECT COUNT(*) FROM sys.foreign_key_columns z WHERE z.constraint_object_id=f.object_id)=1
        )
    ) THROW 50005, 'Expected trusted foreign keys are missing. Use a new lab database.', 1;

    IF NOT EXISTS (
        SELECT 1 FROM sys.indexes i WHERE i.object_id=OBJECT_ID(N'dbo.Enrollments') AND i.is_unique=1 AND i.has_filter=0
        AND (SELECT COUNT(*) FROM sys.index_columns k WHERE k.object_id=i.object_id AND k.index_id=i.index_id AND k.key_ordinal>0)=2
        AND EXISTS (SELECT 1 FROM sys.index_columns k JOIN sys.columns c ON c.object_id=k.object_id AND c.column_id=k.column_id WHERE k.object_id=i.object_id AND k.index_id=i.index_id AND k.key_ordinal>0 AND c.name='StudentId')
        AND EXISTS (SELECT 1 FROM sys.index_columns k JOIN sys.columns c ON c.object_id=k.object_id AND c.column_id=k.column_id WHERE k.object_id=i.object_id AND k.index_id=i.index_id AND k.key_ordinal>0 AND c.name='CourseId')
    ) THROW 50006, 'Expected unique enrollment pair is missing. Use a new lab database.', 1;

    -- Dynamic batch compiles only after schema validation has succeeded.
    EXEC sp_executesql N'
        IF EXISTS (SELECT 1 FROM dbo.Students s JOIN (VALUES (1,N''Lina''),(2,N''Omar''),(3,N''Reem''),(4,N''Sara'')) v(Id,Name) ON s.StudentId=v.Id WHERE s.FullName<>v.Name)
            THROW 50007, ''Seed student IDs conflict with existing data. Use a new lab database.'', 1;
        IF EXISTS (SELECT 1 FROM dbo.Courses c JOIN (VALUES (101,N''Database Management'',3),(102,N''Web Development'',3),(103,N''Computer Networks'',2)) v(Id,Name,Hours) ON c.CourseId=v.Id WHERE c.CourseName<>v.Name OR c.CreditHours<>v.Hours)
            THROW 50008, ''Seed course IDs conflict with existing data. Use a new lab database.'', 1;
        IF EXISTS (SELECT 1 FROM dbo.Enrollments e JOIN (VALUES (1,1,101),(2,1,102),(3,2,103),(4,3,101)) v(Id,Student,Course) ON e.EnrollmentId=v.Id WHERE e.StudentId<>v.Student OR e.CourseId<>v.Course)
            THROW 50009, ''Seed enrollment IDs conflict with existing data. Use a new lab database.'', 1;
        INSERT dbo.Students(StudentId,FullName) SELECT v.Id,v.Name FROM (VALUES (1,N''Lina''),(2,N''Omar''),(3,N''Reem''),(4,N''Sara'')) v(Id,Name) WHERE NOT EXISTS (SELECT 1 FROM dbo.Students s WHERE s.StudentId=v.Id);
        INSERT dbo.Courses(CourseId,CourseName,CreditHours) SELECT v.Id,v.Name,v.Hours FROM (VALUES (101,N''Database Management'',3),(102,N''Web Development'',3),(103,N''Computer Networks'',2)) v(Id,Name,Hours) WHERE NOT EXISTS (SELECT 1 FROM dbo.Courses c WHERE c.CourseId=v.Id);
        INSERT dbo.Enrollments(EnrollmentId,StudentId,CourseId) SELECT v.Id,v.Student,v.Course FROM (VALUES (1,1,101),(2,1,102),(3,2,103),(4,3,101)) v(Id,Student,Course) WHERE NOT EXISTS (SELECT 1 FROM dbo.Enrollments e WHERE e.EnrollmentId=v.Id);
    ';
    COMMIT;
    PRINT 'Session 02 foundation validated. Continue to the Session 03 expansion below.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK;
    THROW;
END CATCH;

GO
-- Part 2: add Session 03 columns/tables without dropping or renaming the old ones.
-- Run this entire file, not a selected fragment. SQL migration syntax is supplied support.
USE TVET_DBM_Lab01;
GO
SET XACT_ABORT ON;
BEGIN TRY
    BEGIN TRANSACTION;
    IF OBJECT_ID(N'dbo.Programs',N'U') IS NULL
        CREATE TABLE dbo.Programs (
            ProgramId INT NOT NULL CONSTRAINT PK_Programs PRIMARY KEY,
            ProgramName NVARCHAR(100) NOT NULL
        );
    IF OBJECT_ID(N'dbo.Instructors',N'U') IS NULL
        CREATE TABLE dbo.Instructors (
            InstructorId INT NOT NULL CONSTRAINT PK_Instructors PRIMARY KEY,
            FullName NVARCHAR(80) NOT NULL
        );
    IF COL_LENGTH('dbo.Students','ProgramId') IS NULL
        ALTER TABLE dbo.Students ADD ProgramId INT NULL;
    IF COL_LENGTH('dbo.Students','Email') IS NULL
        ALTER TABLE dbo.Students ADD Email NVARCHAR(120) NULL;
    IF COL_LENGTH('dbo.Courses','InstructorId') IS NULL
        ALTER TABLE dbo.Courses ADD InstructorId INT NULL;
    IF COL_LENGTH('dbo.Courses','Fee') IS NULL
        ALTER TABLE dbo.Courses ADD Fee DECIMAL(8,2) NOT NULL CONSTRAINT DF_Courses_Fee DEFAULT(0) WITH VALUES;
    IF COL_LENGTH('dbo.Courses','StartDate') IS NULL
        ALTER TABLE dbo.Courses ADD StartDate DATE NOT NULL CONSTRAINT DF_Courses_StartDate DEFAULT('20261108') WITH VALUES;
    IF COL_LENGTH('dbo.Courses','IsActive') IS NULL
        ALTER TABLE dbo.Courses ADD IsActive BIT NOT NULL CONSTRAINT DF_Courses_IsActive DEFAULT(1) WITH VALUES;
    IF COL_LENGTH('dbo.Enrollments','EnrolledOn') IS NULL
        ALTER TABLE dbo.Enrollments ADD EnrolledOn DATE NOT NULL CONSTRAINT DF_Enrollments_EnrolledOn DEFAULT('20261108') WITH VALUES;
    IF COL_LENGTH('dbo.Enrollments','Grade') IS NULL
        ALTER TABLE dbo.Enrollments ADD Grade DECIMAL(5,2) NULL;

    -- Fail rather than guess when an existing added column has a different definition.
    DECLARE @Added TABLE(T SYSNAME,C SYSNAME,Ty SYSNAME,L SMALLINT,N BIT,P TINYINT,S TINYINT);
    INSERT @Added VALUES
      ('Programs','ProgramId','int',4,0,10,0),('Programs','ProgramName','nvarchar',200,0,0,0),
      ('Instructors','InstructorId','int',4,0,10,0),('Instructors','FullName','nvarchar',160,0,0,0),
      ('Students','ProgramId','int',4,1,10,0),('Students','Email','nvarchar',240,1,0,0),
      ('Courses','InstructorId','int',4,1,10,0),('Courses','Fee','decimal',5,0,8,2),
      ('Courses','StartDate','date',3,0,10,0),('Courses','IsActive','bit',1,0,1,0),
      ('Enrollments','EnrolledOn','date',3,0,10,0),('Enrollments','Grade','decimal',5,1,5,2);
    IF EXISTS(SELECT 1 FROM @Added e LEFT JOIN sys.columns c
      ON c.object_id=OBJECT_ID(N'dbo.'+e.T) AND c.name=e.C
      WHERE c.column_id IS NULL OR TYPE_NAME(c.user_type_id)<>e.Ty OR c.max_length<>e.L
        OR c.is_nullable<>e.N OR c.is_computed<>0 OR c.is_identity<>0
        OR (e.Ty='decimal' AND (c.precision<>e.P OR c.scale<>e.S)))
        THROW 50101, 'Session 03 schema conflicts with existing definitions. Changes rolled back; ask the instructor.', 1;

    IF NOT EXISTS(SELECT 1 FROM sys.foreign_keys WHERE name='FK_Students_Programs')
        EXEC(N'ALTER TABLE dbo.Students WITH CHECK ADD CONSTRAINT FK_Students_Programs FOREIGN KEY(ProgramId) REFERENCES dbo.Programs(ProgramId);');
    IF NOT EXISTS(SELECT 1 FROM sys.foreign_keys WHERE name='FK_Courses_Instructors')
        EXEC(N'ALTER TABLE dbo.Courses WITH CHECK ADD CONSTRAINT FK_Courses_Instructors FOREIGN KEY(InstructorId) REFERENCES dbo.Instructors(InstructorId);');
    IF NOT EXISTS(SELECT 1 FROM sys.check_constraints WHERE name='CK_Courses_Fee')
        EXEC(N'ALTER TABLE dbo.Courses WITH CHECK ADD CONSTRAINT CK_Courses_Fee CHECK(Fee >= 0);');
    IF NOT EXISTS(SELECT 1 FROM sys.check_constraints WHERE name='CK_Courses_CreditHours')
        ALTER TABLE dbo.Courses WITH CHECK ADD CONSTRAINT CK_Courses_CreditHours CHECK(CreditHours BETWEEN 1 AND 6);
    IF NOT EXISTS(SELECT 1 FROM sys.check_constraints WHERE name='CK_Enrollments_Grade')
        EXEC(N'ALTER TABLE dbo.Enrollments WITH CHECK ADD CONSTRAINT CK_Enrollments_Grade CHECK(Grade BETWEEN 0 AND 100);');
    -- This lesson depends on NO ACTION deletion of referenced courses.
    IF EXISTS(SELECT 1 FROM sys.foreign_keys WHERE parent_object_id=OBJECT_ID('dbo.Enrollments')
      AND referenced_object_id=OBJECT_ID('dbo.Courses') AND (delete_referential_action<>0 OR is_disabled=1 OR is_not_trusted=1))
        THROW 50102, 'The course foreign key must use trusted NO ACTION behavior for this lesson.', 1;

    IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'DB3.Session03.Seeded')
    BEGIN
        -- Compile this batch after the new columns exist. All seed values are classroom examples.
        EXEC sp_executesql N'IF EXISTS(SELECT 1 FROM dbo.Programs t JOIN (VALUES (10,N''Programming and Database''),
        (20,N''Networks''),
        (30,N''Business Applications'')) v(ProgramId,ProgramName) ON t.ProgramId=v.ProgramId WHERE t.ProgramName<>v.ProgramName) THROW 50103, ''Reserved Session 03 seed IDs conflict with existing data; no records overwritten.'', 1;
INSERT dbo.Programs(ProgramId,ProgramName) SELECT v.ProgramId,v.ProgramName FROM (VALUES (10,N''Programming and Database''),
        (20,N''Networks''),
        (30,N''Business Applications'')) v(ProgramId,ProgramName) WHERE NOT EXISTS(SELECT 1 FROM dbo.Programs t WHERE t.ProgramId=v.ProgramId);
IF EXISTS(SELECT 1 FROM dbo.Instructors t JOIN (VALUES (11,N''Huda''),
        (12,N''Nabil''),
        (13,N''Salma'')) v(InstructorId,FullName) ON t.InstructorId=v.InstructorId WHERE t.FullName<>v.FullName) THROW 50103, ''Reserved Session 03 seed IDs conflict with existing data; no records overwritten.'', 1;
INSERT dbo.Instructors(InstructorId,FullName) SELECT v.InstructorId,v.FullName FROM (VALUES (11,N''Huda''),
        (12,N''Nabil''),
        (13,N''Salma'')) v(InstructorId,FullName) WHERE NOT EXISTS(SELECT 1 FROM dbo.Instructors t WHERE t.InstructorId=v.InstructorId);
IF EXISTS(SELECT 1 FROM dbo.Students t JOIN (VALUES (1,N''Lina''),
        (2,N''Omar''),
        (3,N''Reem''),
        (4,N''Sara''),
        (5,N''Yousef''),
        (6,N''Maha''),
        (7,N''Dana''),
        (8,N''Kareem''),
        (9,N''Hala''),
        (10,N''Sami'')) v(StudentId,FullName) ON t.StudentId=v.StudentId WHERE t.FullName<>v.FullName) THROW 50103, ''Reserved Session 03 seed IDs conflict with existing data; no records overwritten.'', 1;
INSERT dbo.Students(StudentId,FullName) SELECT v.StudentId,v.FullName FROM (VALUES (1,N''Lina''),
        (2,N''Omar''),
        (3,N''Reem''),
        (4,N''Sara''),
        (5,N''Yousef''),
        (6,N''Maha''),
        (7,N''Dana''),
        (8,N''Kareem''),
        (9,N''Hala''),
        (10,N''Sami'')) v(StudentId,FullName) WHERE NOT EXISTS(SELECT 1 FROM dbo.Students t WHERE t.StudentId=v.StudentId);
IF EXISTS(SELECT 1 FROM dbo.Courses t JOIN (VALUES (101,N''Database Management'',3),
        (102,N''Web Development'',3),
        (103,N''Computer Networks'',2),
        (104,N''Mobile Development'',3),
        (105,N''Data Analytics'',3),
        (106,N''Business Computing'',2),
        (107,N''Independent Study'',1)) v(CourseId,CourseName,CreditHours) ON t.CourseId=v.CourseId WHERE t.CourseName<>v.CourseName OR t.CreditHours<>v.CreditHours) THROW 50103, ''Reserved Session 03 seed IDs conflict with existing data; no records overwritten.'', 1;
INSERT dbo.Courses(CourseId,CourseName,CreditHours) SELECT v.CourseId,v.CourseName,v.CreditHours FROM (VALUES (101,N''Database Management'',3),
        (102,N''Web Development'',3),
        (103,N''Computer Networks'',2),
        (104,N''Mobile Development'',3),
        (105,N''Data Analytics'',3),
        (106,N''Business Computing'',2),
        (107,N''Independent Study'',1)) v(CourseId,CourseName,CreditHours) WHERE NOT EXISTS(SELECT 1 FROM dbo.Courses t WHERE t.CourseId=v.CourseId);
IF EXISTS(SELECT 1 FROM dbo.Enrollments t JOIN (VALUES (1,1,101),
        (2,1,102),
        (3,2,103),
        (4,3,101),
        (5,5,103),
        (6,5,104),
        (7,6,101),
        (8,6,105),
        (9,7,106),
        (10,8,106),
        (11,9,102),
        (12,9,105),
        (13,10,103),
        (14,1,107),
        (15,3,105),
        (16,6,102)) v(EnrollmentId,StudentId,CourseId) ON t.EnrollmentId=v.EnrollmentId WHERE t.StudentId<>v.StudentId OR t.CourseId<>v.CourseId) THROW 50103, ''Reserved Session 03 seed IDs conflict with existing data; no records overwritten.'', 1;
INSERT dbo.Enrollments(EnrollmentId,StudentId,CourseId) SELECT v.EnrollmentId,v.StudentId,v.CourseId FROM (VALUES (1,1,101),
        (2,1,102),
        (3,2,103),
        (4,3,101),
        (5,5,103),
        (6,5,104),
        (7,6,101),
        (8,6,105),
        (9,7,106),
        (10,8,106),
        (11,9,102),
        (12,9,105),
        (13,10,103),
        (14,1,107),
        (15,3,105),
        (16,6,102)) v(EnrollmentId,StudentId,CourseId) WHERE NOT EXISTS(SELECT 1 FROM dbo.Enrollments t WHERE t.EnrollmentId=v.EnrollmentId);
UPDATE dbo.Students SET ProgramId=10, Email=N''lina@example.test'' WHERE StudentId=1;
UPDATE dbo.Students SET ProgramId=20, Email=N''omar@example.test'' WHERE StudentId=2;
UPDATE dbo.Students SET ProgramId=10, Email=N''reem@example.test'' WHERE StudentId=3;
UPDATE dbo.Students SET ProgramId=10, Email=N''sara@example.test'' WHERE StudentId=4;
UPDATE dbo.Students SET ProgramId=20, Email=N''yousef@example.test'' WHERE StudentId=5;
UPDATE dbo.Students SET ProgramId=10, Email=N''maha@example.test'' WHERE StudentId=6;
UPDATE dbo.Students SET ProgramId=30, Email=N''dana@example.test'' WHERE StudentId=7;
UPDATE dbo.Students SET ProgramId=30, Email=N''kareem@example.test'' WHERE StudentId=8;
UPDATE dbo.Students SET ProgramId=10, Email=N''hala@example.test'' WHERE StudentId=9;
UPDATE dbo.Students SET ProgramId=20, Email=N''sami@example.test'' WHERE StudentId=10;
UPDATE dbo.Courses SET InstructorId=11,Fee=100,StartDate=N''2026-11-08'',IsActive=1 WHERE CourseId=101;
UPDATE dbo.Courses SET InstructorId=12,Fee=90,StartDate=N''2026-11-09'',IsActive=1 WHERE CourseId=102;
UPDATE dbo.Courses SET InstructorId=13,Fee=70,StartDate=N''2026-11-10'',IsActive=1 WHERE CourseId=103;
UPDATE dbo.Courses SET InstructorId=12,Fee=120,StartDate=N''2026-11-11'',IsActive=1 WHERE CourseId=104;
UPDATE dbo.Courses SET InstructorId=11,Fee=110,StartDate=N''2026-11-12'',IsActive=1 WHERE CourseId=105;
UPDATE dbo.Courses SET InstructorId=13,Fee=0,StartDate=N''2026-11-13'',IsActive=1 WHERE CourseId=106;
UPDATE dbo.Courses SET InstructorId=NULL,Fee=40,StartDate=N''2026-11-14'',IsActive=1 WHERE CourseId=107;
UPDATE dbo.Enrollments SET Grade=85 WHERE EnrollmentId=1;
UPDATE dbo.Enrollments SET Grade=NULL WHERE EnrollmentId=2;
UPDATE dbo.Enrollments SET Grade=76 WHERE EnrollmentId=3;
UPDATE dbo.Enrollments SET Grade=92 WHERE EnrollmentId=4;
UPDATE dbo.Enrollments SET Grade=78 WHERE EnrollmentId=5;
UPDATE dbo.Enrollments SET Grade=NULL WHERE EnrollmentId=6;
UPDATE dbo.Enrollments SET Grade=95 WHERE EnrollmentId=7;
UPDATE dbo.Enrollments SET Grade=NULL WHERE EnrollmentId=8;
UPDATE dbo.Enrollments SET Grade=88 WHERE EnrollmentId=9;
UPDATE dbo.Enrollments SET Grade=NULL WHERE EnrollmentId=10;
UPDATE dbo.Enrollments SET Grade=91 WHERE EnrollmentId=11;
UPDATE dbo.Enrollments SET Grade=NULL WHERE EnrollmentId=12;
UPDATE dbo.Enrollments SET Grade=0 WHERE EnrollmentId=13;
UPDATE dbo.Enrollments SET Grade=NULL WHERE EnrollmentId=14;
UPDATE dbo.Enrollments SET Grade=NULL WHERE EnrollmentId=15;
UPDATE dbo.Enrollments SET Grade=89 WHERE EnrollmentId=16;';
        EXEC sys.sp_addextendedproperty @name=N'DB3.Session03.Seeded', @value=N'1';
    END;
    COMMIT;
    SELECT 'Students' AS TableName,COUNT(*) AS [RowCount] FROM dbo.Students
    UNION ALL SELECT 'Courses',COUNT(*) FROM dbo.Courses
    UNION ALL SELECT 'Enrollments',COUNT(*) FROM dbo.Enrollments
    UNION ALL SELECT 'Programs',COUNT(*) FROM dbo.Programs
    UNION ALL SELECT 'Instructors',COUNT(*) FROM dbo.Instructors;
    PRINT 'Session 03 expansion complete. Fresh baseline: 10 students, 7 courses, 16 enrollments, 3 programs, 3 instructors.';
    PRINT 'Course 190 is NOT a seed row. Your INSERT task creates it. Existing extra records and later edits are preserved.';
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK;
    THROW;
END CATCH;
