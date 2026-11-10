/* Deterministic browser teaching model. It never executes C# or SQL. */
(() => {
  'use strict';
  const clone = x => JSON.parse(JSON.stringify(x));
  const positiveInt = x => /^\d+$/.test(String(x).trim()) && Number.isSafeInteger(Number(x)) && Number(x) > 0 && Number(x) <= 2147483647 ? Number(x) : null;
  const money = x => /^\d{1,6}(?:\.\d{1,2})?$/.test(String(x).trim()) ? Number(x) : null;
  const fail = (kind, message, number) => ({ kind, message, number, affected: null });
  function insert(s, input) {
    const id = positiveInt(input.id), instructorId = positiveInt(input.instructorId), fee = money(input.fee), name = String(input.name).trim();
    if (id === null || instructorId === null || fee === null || !name || name.length > 100) return fail('validation', 'Invalid draft values. No connection was opened and no SQL was sent.');
    const existing = s.courses.find(c => c.id === id);
    if (existing) return { ...fail('sql-error', `Course ${id} already exists in this browser dataset. A second INSERT with the same primary key is rejected. Choose another CourseId, or select “Reset browser dataset” to repeat the first insert.`, 2627), existing: clone(existing) };
    if (!s.instructors.some(i => i.id === instructorId)) return fail('sql-error', 'InstructorId is not present in Instructors. The foreign key rejects the insert.', 547);
    const row = { ...clone(s.draft), id, name, instructorId, fee }; s.courses.push(row);
    return { kind: 'success', affected: 1, message: 'Rows inserted: 1. The new course is inactive.', row: clone(row) };
  }
  function update(s, input) {
    const id = positiveInt(input.id), fee = money(input.fee);
    if (id === null || fee === null) return fail('validation', 'Enter a positive integer ID and a fee from 0 to 999999.99, with up to two decimal places. No SQL was sent.');
    const row = s.courses.find(c => c.id === id);
    if (!row) return { kind: 'no-match', affected: 0, message: 'No course matched this ID. Rows updated: 0.' };
    const before = clone(row); row.fee = fee; row.active = input.active === true;
    return { kind: 'success', affected: 1, before, after: clone(row), message: 'Rows updated: 1. A row matched the key, even if its values already matched.' };
  }
  function remove(s, input) {
    const id = positiveInt(input.id);
    if (id === null) return fail('validation', 'Enter a positive integer. No connection was opened and no SQL was sent.');
    const links = s.enrollments.filter(e => e.courseId === id);
    if (links.length) return { ...fail('sql-error', 'A course with enrollment references cannot be deleted under this NO ACTION foreign key.', 547), links: clone(links) };
    const index = s.courses.findIndex(c => c.id === id);
    if (index < 0) return { kind: 'no-match', affected: 0, message: 'No course matched this ID. Rows deleted: 0.' };
    const before = s.courses.splice(index, 1)[0]; return { kind: 'success', affected: 1, before, message: 'Rows deleted: 1. Enrollment records were not changed.' };
  }
  function report(s, input) {
    const programId = positiveInt(input.programId), minimumFee = money(input.minimumFee);
    if (programId === null || minimumFee === null) return { ...fail('validation', 'Check the filters before sending a command.'), rows: [] };
    const rows = [];
    for (const e of s.enrollments) {
      const student = s.students.find(x => x.id === e.studentId), course = s.courses.find(x => x.id === e.courseId);
      if (!student || !course || student.programId !== programId || course.fee < minimumFee || course.active !== (input.active === true)) continue;
      const program = s.programs.find(x => x.id === student.programId); if (!program) continue;
      const instructor = s.instructors.find(x => x.id === course.instructorId);
      rows.push({ studentId: student.id, courseId: course.id, studentName: student.name, programName: program.name, courseName: course.name, instructorName: instructor?.name ?? null, fee: course.fee, startDate: course.startDate, grade: e.grade });
    }
    rows.sort((a, b) => a.studentId - b.studentId || a.courseId - b.courseId);
    return { kind: 'success', rows, students: new Set(rows.map(x => x.studentId)).size };
  }
  globalThis.DB3Engine = { clone, positiveInt, money, insert, update, remove, report };
})();
