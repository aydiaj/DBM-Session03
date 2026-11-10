/* Simulated database records for the teaching activities. */
window.DB3_DATA = {
  programs: [{ id: 10, name: 'Programming and Database' }, { id: 20, name: 'Networks' }, { id: 30, name: 'Business Applications' }],
  instructors: [{ id: 11, name: 'Huda' }, { id: 12, name: 'Nabil' }, { id: 13, name: 'Salma' }],
  students: [
    [1, 'Lina', 10], [2, 'Omar', 20], [3, 'Reem', 10], [4, 'Sara', 10], [5, 'Yousef', 20],
    [6, 'Maha', 10], [7, 'Dana', 30], [8, 'Kareem', 30], [9, 'Hala', 10], [10, 'Sami', 20]
  ].map(([id, name, programId]) => ({ id, name, programId })),
  courses: [
    [101, 'Database Management', 3, 11, 100, '2026-11-08', true],
    [102, 'Web Development', 3, 12, 90, '2026-11-09', true],
    [103, 'Computer Networks', 2, 13, 70, '2026-11-10', true],
    [104, 'Mobile Development', 3, 12, 120, '2026-11-11', true],
    [105, 'Data Analytics', 3, 11, 110, '2026-11-12', true],
    [106, 'Business Computing', 2, 13, 0, '2026-11-13', true],
    [107, 'Independent Study', 1, null, 40, '2026-11-14', true]
  ].map(([id, name, hours, instructorId, fee, startDate, active]) => ({ id, name, hours, instructorId, fee, startDate, active })),
  enrollments: [
    [1, 1, 101, 85], [2, 1, 102, null], [3, 2, 103, 76], [4, 3, 101, 92],
    [5, 5, 103, 78], [6, 5, 104, null], [7, 6, 101, 95], [8, 6, 105, null],
    [9, 7, 106, 88], [10, 8, 106, null], [11, 9, 102, 91], [12, 9, 105, null],
    [13, 10, 103, 0], [14, 1, 107, null], [15, 3, 105, null], [16, 6, 102, 89]
  ].map(([id, studentId, courseId, grade]) => ({ id, studentId, courseId, grade })),
  draft: { id: 190, name: "Trainer's SQL Workshop", hours: 3, instructorId: 11, fee: 75.50, startDate: '2026-11-16', active: false }
};
