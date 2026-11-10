# DB3 Session 03 - Student starter

1. Extract this ZIP to a writable folder. Open DB3.Session03.csproj in Visual Studio.
2. Use Visual Studio 2026 with the .NET desktop development workload and .NET 10 SDK.
3. Allow NuGet restore. References: Microsoft.Data.SqlClient 7.1.1 and System.Security.Cryptography.Pkcs 10.0.14.
4. Run the complete setup-session03.sql in SSMS on the same SQL Server instance. It includes the Session 02 foundation and the additive expansion.
5. Edit YOUR_SERVER in Program.cs. Windows authentication is assumed. Local classroom certificate settings are explained in the lesson.
6. Run with Ctrl+F5. Choose one supplied activity, 1 to 4. Before TODOs are completed, it prints honest placeholder messages and does not contact SQL Server.
7. Complete TODOs 01-04 using the website. Only one activity executes per run, so you can test each checkpoint separately.

The original Students, Courses and Enrollments names and existing columns stay available. The SQL script adds Programs, Instructors and richer fields. Do not run the old Session 02 setup script after expansion; its strict column-count checks reject the expanded schema.

Fresh baseline: 10 students, 7 courses, 16 enrollments, 3 programs, 3 instructors. Existing extra rows may increase those counts. Course 190 is deliberately absent.

Suggested run order: insert 190 -> update 190 -> report -> delete 190. Repeating insert before delete produces a duplicate-key error; repeating delete produces zero matching rows. Deleting 101 is blocked by an enrollment foreign key. Invalid text/negative IDs are rejected before database access.

The setup script seeds expansion metadata once. Rerunning it does not reset course fee/status edits or delete extra records. Browser simulation reset affects only the browser and never resets SQL Server.

The project uses top-level statements. No explicit internal Program class, Task Main signature or dummy await is needed. Database calls still use await. An outer catch displays an error and ends that run; correct the cause and run the selected activity again.

Verification: see the instructor validation report for actual authoring checks and the separate classroom SQL smoke test. Do not infer a live SQL test from a successful browser simulation.

Next scheduled lesson: Session 04 - Your first EF Core application (entities, DbContext, DbSet, SQL Server provider, first query and generated SQL). This session completes the introductory ADO.NET sequence; transactions and stored procedures remain later syllabus topics.
