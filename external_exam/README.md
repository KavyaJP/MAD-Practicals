# Exam Timetable App

**Problem Definition:** *Students often struggle to track upcoming exam schedules and venues. Create a Flutter application that acts as a personalized exam timetable.*

## Requirements:

### Exam Entry
- Each exam entry should contain Course Code, Date, Time, Venue.
- Provide an option to upload supporting documents (e.g., seating plan, syllabus, hall ticket PDF).

### Exam Display:
- Display exams in a scrollable list ordered by date & time.
- Each item shows course code, date, time, venue, and document availability (icon if uploaded).

### Search Feature:
- Provide a search bar to find an exam schedule by course code.

### Upcoming Exam Countdown:
- Identify the nearest upcoming exam based on current date.
- Show countdown in days (“Next Exam in 3 days: CS301 – DBMS”).

### Persistence:
- Store exam details and uploaded file paths in SQLite (preferred).
- Alternative: SharedPreferences or another local DB.

### Navigation:
- Exam List Screen (view all exams & search).
- Exam Entry Screen (add/edit exams, upload document).

### UI/UX Expectations:
- Use DatePicker & TimePicker widgets.
- Highlight nearest exam with different UI style.
- Show an attachment icon for uploaded documents.

## Bonus (Optional):
- Allow students to open/download uploaded files.
- Provide a “Remind Me” toggle for notification setup.