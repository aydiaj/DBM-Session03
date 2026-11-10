using System.Data;
using Microsoft.Data.SqlClient;

// DB3 Session 03 - Safe Data Changes. Complete one TODO at a time.
// Top-level statements allow await without writing a Task Main signature.
// The activity selector, input validation and error handling are supplied.
Console.WriteLine("DB3 - From Reading Data to Safe Data Changes");

// TODO 00 - Use the SAME SQL Server instance as SSMS.
// Run setup-session03.sql before any database activity.
// TrustServerCertificate=True is for this local classroom instance only.
string connectionString =
    @"Server=YOUR_SERVER;Database=TVET_DBM_Lab01;Integrated Security=True;Encrypt=True;TrustServerCertificate=True;Connect Timeout=10;";

Console.Write("Activity (1 insert, 2 update, 3 delete, 4 report): ");
if (!int.TryParse(Console.ReadLine(), out int activity) || activity < 1 || activity > 4)
{
    Console.WriteLine("Choose an activity from 1 to 4. No SQL was sent.");
    return;
}

try
{
    if (string.IsNullOrWhiteSpace(connectionString))
    {
        Console.WriteLine("Prepare a connection string first. No SQL was sent.");
        return;
    }
    if (activity == 1)
    {
        // Supplied draft: read these types before adding parameters.
        int courseId = 190;
        string courseName = "Trainer's SQL Workshop";
        int creditHours = 3;
        int instructorId = 11;
        decimal fee = 75.50m;
        DateTime startDate = new DateTime(2026, 11, 16);
        bool isActive = false;
        // Validation happens before creating/opening a connection.
        if (courseId <= 0 || string.IsNullOrWhiteSpace(courseName) || courseName.Length > 100
            || creditHours < 1 || creditHours > 6 || instructorId <= 0
            || fee < 0 || fee > 999999.99m)
        {
            Console.WriteLine("Check the draft values. No SQL was sent.");
            return;
        }
        Console.WriteLine($"Prepared draft: {courseId}; active = {isActive}. Not saved yet.");
        // TODO 01 - Insert this course with seven explicitly typed parameters.
        // NVarChar needs Size 100; Decimal needs Precision 8 and Scale 2.
        // Use ExecuteNonQueryAsync and print the affected-row count.
        Console.WriteLine("TODO 01: not implemented yet.");
    }
    else if (activity == 2)
    {
        Console.Write("CourseId to update (190 after insert, 99 or abc): ");
        if (!int.TryParse(Console.ReadLine(), out int courseId) || courseId <= 0)
        {
            Console.WriteLine("Enter a positive integer. No SQL was sent.");
            return;
        }
        decimal newFee = 89.50m;
        bool isActive = true;
        if (newFee < 0 || newFee > 999999.99m)
        {
            Console.WriteLine("Fee must be between 0 and 999999.99. No SQL was sent.");
            return;
        }
        Console.WriteLine($"Prepared change: fee = {newFee:0.00}; active = {isActive}. Not saved yet.");
        // TODO 02 - Update Fee and IsActive WHERE CourseId = @courseId.
        // Use typed Int, Decimal(8,2), and Bit parameters.
        // Distinguish zero matching rows from a SQL exception.
        Console.WriteLine("TODO 02: not implemented yet.");
    }
    else if (activity == 3)
    {
        Console.Write("CourseId to delete (190, 99; 101 is referenced): ");
        if (!int.TryParse(Console.ReadLine(), out int courseId) || courseId <= 0)
        {
            Console.WriteLine("Enter a positive integer. No SQL was sent.");
            return;
        }
        // TODO 03 - Delete only the course selected by @courseId.
        // Course 190 has no enrollments; course 101 has enrollments.
        // The foreign key protects existing enrollment references.
        Console.WriteLine("TODO 03: not implemented yet.");
    }
    else
    {
        // Supplied filter values. Change one at a time and predict the rows.
        int programId = 10;
        decimal minimumFee = 0m;
        bool isActive = true;
        if (programId <= 0 || minimumFee < 0 || minimumFee > 999999.99m)
        {
            Console.WriteLine("Check the filters. No SQL was sent.");
            return;
        }
        Console.WriteLine($"Prepared filters: programme = {programId}; minimum fee = {minimumFee:0.00}; active = {isActive}.");
        // TODO 04 - Guided report: use the supplied five-table SELECT.
        // Add three typed parameters and read the seven result columns.
        // Check IsDBNull before reading optional instructor/grade values.
        Console.WriteLine("TODO 04: not implemented yet.");
    }
}
catch (SqlException ex)
{
    Console.WriteLine($"SQL Server error {ex.Number}: {ex.Message}");
    if (ex.Number == 2601 || ex.Number == 2627)
        Console.WriteLine("This key already exists. Use another ID, or continue with update/delete.");
    else if (ex.Number == 547)
        Console.WriteLine("A relationship or CHECK rule prevented this change. Inspect the named constraint.");
    else
        Console.WriteLine("Check the server connection, database setup and SQL command.");
}
catch (ArgumentException ex)
{
    Console.WriteLine($"Check the connection string or parameter arguments: {ex.Message}");
}
catch (InvalidCastException ex)
{
    Console.WriteLine($"Check the result-column types and reader getters: {ex.Message}");
}
catch (InvalidOperationException ex)
{
    Console.WriteLine($"Check the connection state, command setup and reader usage: {ex.Message}");
}
