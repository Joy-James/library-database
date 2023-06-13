USE [library management system]

-- Create Books table
CREATE TABLE Books (
  BookID INT PRIMARY KEY,
  Title VARCHAR(255),
  Author VARCHAR(255),
  PublicationYear INT,
  Status VARCHAR(20)
);

-- Create Members table
CREATE TABLE Members (
  MemberID INT PRIMARY KEY,
  Name VARCHAR(255),
  Address VARCHAR(255),
  ContactNumber VARCHAR(20)
);

-- Create Loans table
CREATE TABLE Loans (
  LoanID INT PRIMARY KEY,
  BookID INT,
  MemberID INT,
  LoanDate DATE,
  ReturnDate DATE,
  FOREIGN KEY (BookID) REFERENCES Books(BookID),
  FOREIGN KEY (MemberID) REFERENCES Members(MemberID)
);
SELECT*FROM Loans
SELECT*FROM Members
SELECT*FROM Books

INSERT INTO Books (BookID, Title, Author, PublicationYear, Status) VALUES
(7441, 'To Kill a Mockingbird', 'Harper Lee', 1960, 'Available'),
(7442, '1984', 'George Orwell', 1949, 'Available'),
(7443, 'Pride and Prejudice', 'Jane Austen', 1813, 'Available'),
(7444, 'The Great Gatsby', 'F. Scott Fitzgerald', 1925, 'On Loan'),
(7445, 'The Catcher in the Rye', 'J.D. Salinger', 1951, 'Available');

INSERT INTO Members (MemberID, Name, Address, ContactNumber) VALUES
(11, 'John Smith', '123 Main St, City', '555-1234'),
(12, 'Jane Doe', '456 Elm St, Town', '555-5678'),
(13, 'David Johnson', '789 Oak St, Village', '555-9012'),
(14, 'Emily Wilson', '321 Pine St, Hamlet', '555-3456');

INSERT INTO Loans (LoanID, BookID, MemberID, LoanDate, ReturnDate) VALUES
(1, 7441, 12, '2023-06-01', '2023-06-15'),
(2, 7443, 11, '2023-06-05', '2023-06-12'),
(3, 7444, 13, '2023-06-08', '2023-06-22'),
(4, 7442, 14, '2023-06-10', '2023-06-17');


--trigger that automatically updates the "Status" column in the "Books" table 

CREATE TRIGGER UpdateBookStatus
ON Loans
AFTER INSERT
AS
BEGIN
  SET NOCOUNT ON;
  
  DECLARE @bookID INT;
  DECLARE @bookStatus VARCHAR(20);
  
  SELECT @bookID = BookID FROM inserted;
  
  IF EXISTS (SELECT 1 FROM Loans WHERE BookID = @bookID)
    SET @bookStatus = 'Loaned';
  ELSE
    SET @bookStatus = 'Available';
  
  UPDATE Books
  SET Status = @bookStatus
  WHERE BookID = @bookID;
END;
INSERT INTO Loans (LoanID, BookID, MemberID, LoanDate, ReturnDate)
VALUES (1, 7441, 12, '2023-06-01', '2023-06-15');

--Create a CTE that retrieves the names of all members who have borrowed at least three books.

WITH BorrowedBooksCount AS (
  SELECT MemberID, COUNT(*) AS NumBooksBorrowed
  FROM Loans
  GROUP BY MemberID
)
SELECT M.Name
FROM Members M
JOIN BorrowedBooksCount B ON M.MemberID = B.MemberID
WHERE B.NumBooksBorrowed <= 3;

CREATE FUNCTION CalculateOverdueDays (@LoanID INT)
RETURNS INT
AS
BEGIN
    DECLARE @OverdueDays INT;

    SELECT @OverdueDays = DATEDIFF(DAY, L.ReturnDate, GETDATE())
    FROM Loans L
    WHERE L.LoanID = @LoanID;

    IF @OverdueDays < 0
        SET @OverdueDays = 0;

    RETURN @OverdueDays;
END;

CREATE TRIGGER PreventExcessiveBorrowing
ON Loans
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
  
    DECLARE @MemberID INT;
    DECLARE @BooksBorrowed INT;

    SELECT @MemberID = MemberID FROM inserted;
    
    SELECT @BooksBorrowed = COUNT(*) 
    FROM Loans
    WHERE MemberID = @MemberID;
    
    IF @BooksBorrowed >= 3
    BEGIN
        RAISERROR('The member already has 3 books on loan. Cannot borrow more books.', 16, 1);
        ROLLBACK TRANSACTION;
    END;
END;
