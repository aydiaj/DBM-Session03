# DB3 Session 03 - From Reading Data to Safe Data Changes

100-minute, offline-capable static codelab for GTC / Programming and Database Level 2.

## Classroom files

- downloads/DB3_Session03_Student_Starter.zip: prepared .NET 10 Console project, supporting validation and numbered TODOs.
- downloads/setup-session03.sql: original foundation plus additive schema/data expansion in TVET_DBM_Lab01.
- downloads/DB3_Session03_Checkpoint01.zip to Checkpoint04.zip: complete cumulative reference versions, also linked inside answer disclosures.
- downloads/DB3_Session03_Homework.pdf: one A4 page; the deadline is before Session 04.
- downloads/START-HERE.md: exact classroom opening instructions.

## Teaching decision

This session closes the introductory ADO.NET sequence. Next scheduled lesson: Session 04, the first EF Core application. The instructor pack documents the scope assessment and a conditional recovery plan; no extra ADO.NET session is scheduled automatically.

Core scope: typed INSERT/UPDATE/DELETE, row counts versus exceptions, relationship constraints, richer reader results and NULL, resource lifetime, and a conceptual manual-mapping bridge. SQL setup is supplied; the five-table report is guided. 

## Dataset

Fresh baseline: Students 10, Courses 7, Enrollments 16, Programs 3, Instructors 3. Existing extra records are preserved and can change real counts. The original names and columns stay available. Course 190 is absent until the insert task creates it. The simplified model represents one registration period; repeated semester offerings require an intentional CourseOffering model later.

The browser model shares temporary course changes between insert/update/delete/report activities. Reset affects the browser model only. Learning progress uses db3-session03-core-100-v1; it does not overwrite Session 02 progress. 

