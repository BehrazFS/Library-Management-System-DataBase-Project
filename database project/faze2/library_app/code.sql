USE master;
GO
IF DB_ID('LibraryManagementDB') IS NOT NULL
BEGIN
    ALTER DATABASE LibraryManagementDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE LibraryManagementDB;
END
GO
CREATE DATABASE LibraryManagementDB;
GO
USE LibraryManagementDB;
GO

CREATE TABLE Writer (
    WriterID INT PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    LastName NVARCHAR(100) NOT NULL
);

CREATE TABLE Book (
    BookID INT PRIMARY KEY,
    Title NVARCHAR(200) NOT NULL,
    Publisher NVARCHAR(100),
    PublishedYear INT CHECK (PublishedYear >= 0),
    Translator NVARCHAR(100),
    Genre NVARCHAR(100)
);

CREATE TABLE Copy (
    CopyID INT PRIMARY KEY,
    BookID INT NOT NULL,
    State NVARCHAR(20) NOT NULL CHECK (State IN (N'Available', N'Borrowed')),
    FOREIGN KEY (BookID) REFERENCES Book(BookID) ON DELETE CASCADE
);

CREATE TABLE WriterBook (
    WriterID INT,
    BookID INT,
    PRIMARY KEY (WriterID, BookID),
    FOREIGN KEY (WriterID) REFERENCES Writer(WriterID) ON DELETE CASCADE,
    FOREIGN KEY (BookID) REFERENCES Book(BookID) ON DELETE CASCADE
);

CREATE TABLE Member (
    MemberID INT PRIMARY KEY,
    Name NVARCHAR(100),
    LastName NVARCHAR(100),
    Password NVARCHAR(100) NOT NULL,
    Address NVARCHAR(255),
    RegistrationDate DATE,
    MaximumNumberOfBorrowedBooks INT CHECK (MaximumNumberOfBorrowedBooks >= 0),
    TypeOfMembership NVARCHAR(50) NOT NULL CHECK (TypeOfMembership IN (N'Basic', N'VIP')),
    PhoneNumber NVARCHAR(20)
);

-- CREATE TABLE PhoneNumbers (
--     MemberID INT,
--     PhoneNumber NVARCHAR(20),
--     PRIMARY KEY (MemberID, PhoneNumber),
--     FOREIGN KEY (MemberID) REFERENCES Member(MemberID) ON DELETE CASCADE
-- );

CREATE TABLE Employee (
    EmployeeID INT PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    LastName NVARCHAR(100) NOT NULL,
    Password NVARCHAR(100) NOT NULL
);

CREATE TABLE BookBorrowed (
    BookBorrowedID INT PRIMARY KEY,
    MemberID INT,
    CopyID INT,
    BorrowedDate DATE,
    ReturnDate DATE,
    PredictedReturnDate DATE,
    ManagedByEmployeeID INT,
    FOREIGN KEY (MemberID) REFERENCES Member(MemberID) ON DELETE CASCADE,
    FOREIGN KEY (CopyID) REFERENCES Copy(CopyID) ON DELETE CASCADE,
    FOREIGN KEY (ManagedByEmployeeID) REFERENCES Employee(EmployeeID) ON DELETE SET NULL
);

CREATE TABLE LateReturnFine (
    BookBorrowedID INT PRIMARY KEY,
    FineAmount DECIMAL(10,2),
    PaymentStatus NVARCHAR(50) NOT NULL CHECK (PaymentStatus IN (N'Paid', N'Unpaid')),
    ManagedByEmployeeID INT,
    FOREIGN KEY (BookBorrowedID) REFERENCES BookBorrowed(BookBorrowedID) ON DELETE CASCADE,
    FOREIGN KEY (ManagedByEmployeeID) REFERENCES Employee(EmployeeID) ON DELETE SET NULL
);

CREATE TABLE Reservation (
    ReservationID INT PRIMARY KEY,
    MemberID INT NOT NULL,
    BookID INT NOT NULL,
    ReserveDate DATE DEFAULT GETDATE(),
    FOREIGN KEY (MemberID) REFERENCES Member(MemberID) ON DELETE CASCADE,
    FOREIGN KEY (BookID) REFERENCES Book(BookID) ON DELETE CASCADE,
);

GO 
IF OBJECT_ID('add_member', 'P') IS NOT NULL
    DROP PROCEDURE add_member;
GO

CREATE PROCEDURE add_member
    @Name NVARCHAR(100),
    @LastName NVARCHAR(100),
    @Password NVARCHAR(100) ,
    @Address NVARCHAR(255),
    @RegistrationDate DATE,
    @MaximumNumberOfBorrowedBooks INT ,
    @TypeOfMembership NVARCHAR(50),
    @PhoneNumber NVARCHAR(20) 
AS
BEGIN
    INSERT INTO Member (
        MemberID ,
        Name ,
        LastName,
        Password ,
        Address ,
        RegistrationDate ,
        MaximumNumberOfBorrowedBooks,
        TypeOfMembership ,
        PhoneNumber
    )
    VALUES (
        (SELECT ISNULL(MAX(MemberID), 0) + 1 FROM Member),
        @Name ,
        @LastName ,
        @Password ,
        @Address ,
        @RegistrationDate ,
        @MaximumNumberOfBorrowedBooks  ,
        @TypeOfMembership,
        @PhoneNumber
    );
END;
GO
IF OBJECT_ID('edit_member', 'P') IS NOT NULL
    DROP PROCEDURE edit_member;
GO

CREATE PROCEDURE edit_member
    @MemberID INT ,
    @Name NVARCHAR(100),
    @LastName NVARCHAR(100),
    @Password NVARCHAR(100) ,
    @Address NVARCHAR(255),
    @MaximumNumberOfBorrowedBooks INT ,
    @TypeOfMembership NVARCHAR(50),
    @PhoneNumber NVARCHAR(20)
AS
BEGIN
    UPDATE Member 
    SET
        Name = @Name,
        LastName = @LastName,
        Password = @Password,
        Address = @Address,
        MaximumNumberOfBorrowedBooks = @MaximumNumberOfBorrowedBooks,
        TypeOfMembership  = @TypeOfMembership,
        PhoneNumber = @PhoneNumber
    WHERE MemberID = @MemberID 
END;
GO
IF OBJECT_ID('delete_member', 'P') IS NOT NULL
    DROP PROCEDURE delete_member;
GO

CREATE PROCEDURE delete_member
    @MemberID INT 
AS
BEGIN
    IF EXISTS (SELECT 1 FROM BookBorrowed WHERE MemberID = @MemberID AND ReturnDate IS NULL)
    BEGIN
        RAISERROR(N'Members cannot be removed until they return the borrowed books ', 16, 1);
        RETURN;
    END
    DELETE FROM Member 
    WHERE MemberID = @MemberID 
END;
GO
IF OBJECT_ID('get_member', 'P') IS NOT NULL
    DROP PROCEDURE get_member;
GO

CREATE PROCEDURE get_member
    @MemberID INT 
AS
BEGIN
    SELECT * FROM Member
    WHERE MemberID = @MemberID 
END;
GO
IF OBJECT_ID('search_member', 'P') IS NOT NULL
    DROP PROCEDURE search_member;
GO
CREATE PROCEDURE search_member
    @Keyword NVARCHAR(50)
AS
BEGIN
    SELECT MemberID, Name, LastName, Address, RegistrationDate, MaximumNumberOfBorrowedBooks, TypeOfMembership, PhoneNumber  FROM Member
    WHERE Name LIKE '%' + @Keyword + '%'
       OR LastName LIKE '%' + @Keyword + '%'
       OR PhoneNumber LIKE '%' + @Keyword + '%'
END;
GO 
IF OBJECT_ID('add_book', 'P') IS NOT NULL
    DROP PROCEDURE add_book;
GO

CREATE PROCEDURE add_book
    @Title NVARCHAR(200),
    @Publisher NVARCHAR(100),
    @PublishedYear INT,
    @Translator NVARCHAR(100),
    @Genre NVARCHAR(100)
AS
BEGIN
    INSERT INTO Book (
        BookID,
        Title,
        Publisher,
        PublishedYear ,
        Translator,
        Genre
    )
    VALUES (
        (SELECT ISNULL(MAX(BookID), 0) + 1 FROM Book),
        @Title,
        @Publisher,
        @PublishedYear ,
        @Translator,
        @Genre
    );
END;
GO
IF OBJECT_ID('edit_book', 'P') IS NOT NULL
    DROP PROCEDURE edit_book;
GO

CREATE PROCEDURE edit_book
    @BookID INT,
    @Title NVARCHAR(200),
    @Publisher NVARCHAR(100),
    @PublishedYear INT,
    @Translator NVARCHAR(100),
    @Genre NVARCHAR(100)
AS
BEGIN
    UPDATE Book 
    SET
        Title = @Title,
        Publisher = @Publisher,
        PublishedYear = @PublishedYear ,
        Translator = @Translator,
        Genre = @Genre
    WHERE BookID = @BookID
END;
GO
IF OBJECT_ID('get_book', 'P') IS NOT NULL
    DROP PROCEDURE get_book;
GO
CREATE PROCEDURE get_book
    @BookID INT 
AS
BEGIN
    SELECT * FROM Book
    WHERE BookID = @BookID 
END;
GO
IF OBJECT_ID('delete_book', 'P') IS NOT NULL
    DROP PROCEDURE delete_book;
GO

CREATE PROCEDURE delete_book
    @BookID INT 
AS
BEGIN
    IF EXISTS (SELECT 1 FROM Copy WHERE BookID = @BookID AND State = N'Borrowed')
    BEGIN
        RAISERROR(N'Books cannot be removed until all the borrowed copies are returned ', 16, 1);
        RETURN;
    END
    DELETE FROM Book
    WHERE BookID = @BookID 
END;
GO
IF OBJECT_ID('BookView', 'V') IS NOT NULL
    DROP VIEW BookView;
GO
CREATE VIEW BookView AS
SELECT 
    b.BookID,
    b.Title,
    b.Publisher,
    b.PublishedYear,
    b.Translator,
    b.Genre,
    (
        SELECT COUNT(*) 
        FROM Copy c 
        WHERE c.BookID = b.BookID AND c.State = N'Available'
    ) AS AvailableCopies
FROM Book b;
GO
IF OBJECT_ID('search_book', 'P') IS NOT NULL
    DROP PROCEDURE search_book;
GO
CREATE PROCEDURE search_book
    @Keyword NVARCHAR(50)
AS
BEGIN
    SELECT * FROM BookView
    WHERE Title LIKE '%' + @Keyword + '%'
        OR Genre LIKE '%' + @Keyword + '%'
        OR Publisher LIKE '%' + @Keyword + '%'
        OR Translator LIKE '%' + @Keyword + '%';
END;
GO 
IF OBJECT_ID('MemberLoanView', 'V') IS NOT NULL
    DROP VIEW MemberLoanView;
GO
CREATE VIEW MemberLoanView AS
SELECT
    bb.BookBorrowedID AS LoanID,
    b.Title AS BookTitle,
    b.BookID,
    bb.MemberID,
    bb.CopyID ,
    bb.BorrowedDate ,
    bb.ReturnDate ,
    bb.PredictedReturnDate ,
    bb.ManagedByEmployeeID 
FROM BookBorrowed bb
JOIN Book b ON bb.CopyID = b.BookID
WHERE bb.ReturnDate IS NULL;
GO
IF OBJECT_ID('get_member_loans', 'P') IS NOT NULL
    DROP PROCEDURE get_member_loans;
GO
CREATE PROCEDURE get_member_loans
    @MemberID INT
AS
BEGIN
    SELECT * FROM MemberLoanView
    WHERE MemberID = @MemberID;
END;
GO
IF OBJECT_ID('add_copy', 'P') IS NOT NULL
    DROP PROCEDURE add_copy;
GO
CREATE PROCEDURE add_copy
    @BookID INT
AS
BEGIN
    INSERT INTO Copy (
        CopyID,
        BookID,
        State
    )
    VALUES (
        (SELECT ISNULL(MAX(CopyID), 0) + 1 FROM Copy),
        @BookID,
        'Available'
    );
END;
GO
IF OBJECT_ID('delete_copy', 'P') IS NOT NULL
    DROP PROCEDURE delete_copy;
GO

CREATE PROCEDURE delete_copy
    @CopyID INT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM BookBorrowed WHERE CopyID = @CopyID AND ReturnDate IS NULL)
    BEGIN
        RAISERROR(N'Copy cannot be deleted while it is borrowed.', 16, 1);
        RETURN;
    END
    DELETE FROM Copy WHERE CopyID = @CopyID;
END;
GO
IF OBJECT_ID('get_copies', 'P') IS NOT NULL
    DROP VIEW get_copies;
GO
CREATE PROCEDURE get_copies
    @BookID INT
AS
BEGIN
    SELECT CopyID, State FROM Copy
    WHERE BookID = @BookID;
END;
GO
IF OBJECT_ID('ReportFineView', 'V') IS NOT NULL
    DROP VIEW ReportFineView;
GO
CREATE VIEW ReportFineView AS
SELECT
    lf.ManagedByEmployeeID,
    SUM(CASE WHEN lf.PaymentStatus = N'Unpaid' THEN lf.FineAmount ELSE 0 END) AS TotalUnpaidFines,
    SUM(CASE WHEN lf.PaymentStatus = N'Paid' THEN lf.FineAmount ELSE 0 END) AS TotalPaidFines,
    COUNT(DISTINCT CASE WHEN lf.PaymentStatus = N'Unpaid' THEN lf.BookBorrowedID END) AS UnpaidFineCount,
    COUNT(DISTINCT CASE WHEN lf.PaymentStatus = N'Paid' THEN lf.BookBorrowedID END) AS PaidFineCount
FROM LateReturnFine lf
GROUP BY lf.ManagedByEmployeeID;
GO
IF OBJECT_ID('ReportLoanView', 'V') IS NOT NULL
    DROP VIEW ReportLoanView;
GO
CREATE VIEW ReportLoanView AS
SELECT
    bb.ManagedByEmployeeID,
    COUNT(bb.BookBorrowedID) AS TotalLoans,
    SUM(CASE WHEN bb.ReturnDate IS NULL THEN 1 ELSE 0 END) AS ActiveLoans    
FROM BookBorrowed bb
GROUP BY bb.ManagedByEmployeeID 
GO
IF OBJECT_ID('get_report_fines', 'P') IS NOT NULL
    DROP PROCEDURE get_report_fines;
GO
CREATE PROCEDURE get_report_fines
    @ManagedByEmployeeID INT
AS
BEGIN
    SELECT TotalUnpaidFines,TotalPaidFines,UnpaidFineCount,PaidFineCount FROM ReportFineView
    WHERE ManagedByEmployeeID = @ManagedByEmployeeID;
END;
GO
IF OBJECT_ID('get_report_loans', 'P') IS NOT NULL
    DROP PROCEDURE get_report_loans;
GO
CREATE PROCEDURE get_report_loans
    @ManagedByEmployeeID INT
AS
BEGIN    
    SELECT TotalLoans,ActiveLoans FROM ReportLoanView
    WHERE ManagedByEmployeeID = @ManagedByEmployeeID;
END;
GO
IF OBJECT_ID('MemberFineView', 'V') IS NOT NULL
    DROP VIEW MemberFineView;
GO
CREATE VIEW MemberFineView AS
SELECT
    m.MemberID,
    m.Name,
    m.LastName,
    lf.BookBorrowedID,
    lf.FineAmount,
    lf.PaymentStatus
FROM LateReturnFine lf
JOIN BookBorrowed bb ON lf.BookBorrowedID = bb.BookBorrowedID
JOIN Member m ON bb.MemberID = m.MemberID
WHERE lf.PaymentStatus = N'Unpaid';
GO
IF OBJECT_ID('get_member_fines', 'P') IS NOT NULL
    DROP PROCEDURE get_member_fines;
GO
CREATE PROCEDURE get_member_fines
    @MemberID INT
AS
BEGIN
    SELECT * FROM MemberFineView
    WHERE MemberID = @MemberID;
END;
GO
IF OBJECT_ID('LibrarianLoanView', 'V') IS NOT NULL
    DROP VIEW LibrarianLoanView;
GO
CREATE VIEW LibrarianLoanView AS
SELECT
    bb.BookBorrowedID AS LoanID,
    b.Title AS BookTitle,
    b.BookID,
    bb.MemberID,
    bb.CopyID,
    bb.BorrowedDate,
    bb.ReturnDate,
    bb.PredictedReturnDate,
    bb.ManagedByEmployeeID
FROM BookBorrowed bb
JOIN Copy c ON bb.CopyID = c.CopyID
JOIN Book b ON c.BookID = b.BookID
LEFT JOIN Employee e ON bb.ManagedByEmployeeID = e.EmployeeID
WHERE bb.ReturnDate IS NULL
GO
IF OBJECT_ID('get_librarian_loans', 'P') IS NOT NULL
    DROP PROCEDURE get_librarian_loans;
GO
CREATE PROCEDURE get_librarian_loans
    @EmployeeID INT
AS
BEGIN
    SELECT * FROM LibrarianLoanView
    WHERE ManagedByEmployeeID = @EmployeeID;
END;
GO
IF OBJECT_ID('LibrarianFineView', 'V') IS NOT NULL
    DROP VIEW LibrarianFineView;
GO
CREATE VIEW LibrarianFineView AS
SELECT
    bb.ManagedByEmployeeID AS EmployeeID,
    lf.BookBorrowedID,
    lf.FineAmount,
    lf.PaymentStatus,
    m.MemberID,
    m.Name AS MemberName,
    m.LastName AS MemberLastName
FROM LateReturnFine lf
JOIN BookBorrowed bb ON lf.BookBorrowedID = bb.BookBorrowedID
LEFT JOIN Employee e ON bb.ManagedByEmployeeID = e.EmployeeID
JOIN Member m ON bb.MemberID = m.MemberID;
GO
IF OBJECT_ID('get_librarian_fines', 'P') IS NOT NULL
    DROP PROCEDURE get_librarian_fines;
GO
CREATE PROCEDURE get_librarian_fines
    @EmployeeID INT
AS
BEGIN
    SELECT MemberID,MemberName,MemberLastName,BookBorrowedID,FineAmount,PaymentStatus FROM LibrarianFineView
    WHERE EmployeeID = @EmployeeID;
END;
GO
IF OBJECT_ID('register_loan', 'P') IS NOT NULL
    DROP PROCEDURE register_loan;
GO

CREATE PROCEDURE register_loan
    @MemberID INT,
    @BookID INT,
    @EmployeeID INT,
    @PredictedReturnDate DATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AvailableCopies INT;
    DECLARE @ReservedCopies INT;
    DECLARE @CopyID INT;
    DECLARE @IsVIP INT;
    DECLARE @AlreadyReserved INT;
    DECLARE @CurrentBorrowed INT;
    DECLARE @MaxBorrowed INT;

    -- Count available copies
    SELECT @AvailableCopies = COUNT(*) 
    FROM Copy 
    WHERE BookID = @BookID AND State = N'Available';

    -- Count reservations for this book
    SELECT @ReservedCopies = COUNT(*) 
    FROM Reservation 
    WHERE BookID = @BookID;

    -- Check if member is VIP and get max allowed
    SELECT 
        @IsVIP = CASE WHEN TypeOfMembership = N'VIP' THEN 1 ELSE 0 END,
        @MaxBorrowed = MaximumNumberOfBorrowedBooks
    FROM Member WHERE MemberID = @MemberID;

    -- Count current borrowed books by member
    SELECT @CurrentBorrowed = COUNT(*) 
    FROM BookBorrowed 
    WHERE MemberID = @MemberID AND ReturnDate IS NULL;

    -- If available copies > reserved, loan a book
    IF @AvailableCopies > @ReservedCopies
    BEGIN
        IF @CurrentBorrowed >= @MaxBorrowed
        BEGIN
            RAISERROR(N'Member has reached the maximum number of borrowed books.', 16, 1);
            RETURN;
        END

        -- Get an available copy
        SELECT TOP 1 @CopyID = CopyID 
        FROM Copy 
        WHERE BookID = @BookID AND State = N'Available';

        -- Insert into BookBorrowed
        INSERT INTO BookBorrowed (BookBorrowedID, MemberID, CopyID, BorrowedDate, ReturnDate, PredictedReturnDate, ManagedByEmployeeID)
        VALUES (
            (SELECT ISNULL(MAX(BookBorrowedID), 0) + 1 FROM BookBorrowed),
            @MemberID,
            @CopyID,
            GETDATE(),
            NULL,
            @PredictedReturnDate,
            @EmployeeID
        );

        -- Update copy state
        UPDATE Copy SET State = N'Borrowed' WHERE CopyID = @CopyID;
        -- Delete reservations for this book (since it is now borrowed)
        DELETE FROM Reservation
        WHERE BookID = @BookID AND MemberID = @MemberID;  
    END
    ELSE IF @IsVIP = 1
    BEGIN
        -- Check if already reserved
        SELECT @AlreadyReserved = COUNT(*) 
        FROM Reservation 
        WHERE MemberID = @MemberID AND BookID = @BookID;
        
        IF @AlreadyReserved = 0
        BEGIN
            -- Insert reservation
            INSERT INTO Reservation (ReservationID, MemberID, BookID, ReserveDate)
            VALUES (
                (SELECT ISNULL(MAX(ReservationID), 0) + 1 FROM Reservation),
                @MemberID,
                @BookID,
                GETDATE()
            );
        END
        ELSE
        BEGIN
            RAISERROR(N'VIP member has already reserved this book.', 16, 1);
        END
    END
    ELSE
    BEGIN
        RAISERROR(N'No available copies to loan and reservation is only for VIP members.', 16, 1);
    END
END;
GO
IF OBJECT_ID('fine_register', 'P') IS NOT NULL
    DROP PROCEDURE fine_register;
GO

CREATE PROCEDURE fine_register
    @BookBorrowedID INT,
    @ManagedByEmployeeID INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ReturnDate DATE;
    DECLARE @PredictedReturnDate DATE;
    DECLARE @MemberID INT;
    DECLARE @TypeOfMembership NVARCHAR(50);
    DECLARE @DaysLate INT;
    DECLARE @FineAmount DECIMAL(10,2);

    -- Get return info and member
    SELECT 
        @ReturnDate = ReturnDate,
        @PredictedReturnDate = PredictedReturnDate,
        @MemberID = MemberID
    FROM BookBorrowed
    WHERE BookBorrowedID = @BookBorrowedID;

    -- Get membership type
    SELECT @TypeOfMembership = TypeOfMembership
    FROM Member
    WHERE MemberID = @MemberID;

    -- Calculate days late
    SET @DaysLate = DATEDIFF(DAY, @PredictedReturnDate, @ReturnDate);
    IF @DaysLate > 0
    BEGIN
        -- Set fine amount: VIP = 1 per day, Basic = 2 per day
        IF @TypeOfMembership = N'VIP'
            SET @FineAmount = @DaysLate * 100.00;
        ELSE
            SET @FineAmount = @DaysLate * 200.00;

        -- Insert or update fine
        IF EXISTS (SELECT 1 FROM LateReturnFine WHERE BookBorrowedID = @BookBorrowedID)
        BEGIN
            UPDATE LateReturnFine
            SET FineAmount = @FineAmount, PaymentStatus = N'Unpaid',ManagedByEmployeeID = @ManagedByEmployeeID 
            WHERE BookBorrowedID = @BookBorrowedID;
        END
        ELSE
        BEGIN
            INSERT INTO LateReturnFine (BookBorrowedID, FineAmount, PaymentStatus, ManagedByEmployeeID)
            VALUES (@BookBorrowedID, @FineAmount, N'Unpaid', @ManagedByEmployeeID);
        END
    END
END;
GO
IF OBJECT_ID('edit_loan', 'P') IS NOT NULL
    DROP PROCEDURE edit_loan;
GO
CREATE PROCEDURE edit_loan
    @BookBorrowedID INT,
    @ReturnDate DATE,
    @ManagedByEmployeeID INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CopyID INT;
    DECLARE @PredictedReturnDate DATE;

    -- Get CopyID and PredictedReturnDate for this loan
    SELECT 
        @CopyID = CopyID,
        @PredictedReturnDate = PredictedReturnDate
    FROM BookBorrowed
    WHERE BookBorrowedID = @BookBorrowedID;

    -- Update BookBorrowed with ReturnDate
    UPDATE BookBorrowed
    SET ReturnDate = @ReturnDate
    WHERE BookBorrowedID = @BookBorrowedID;

    -- Set the copy as available again
    UPDATE Copy
    SET State = N'Available'
    WHERE CopyID = @CopyID;

    -- If returned late, call fine_register
    IF @ReturnDate > @PredictedReturnDate AND @ReturnDate IS NOT NULL
    BEGIN
        EXEC fine_register @BookBorrowedID = @BookBorrowedID ,@ManagedByEmployeeID = @ManagedByEmployeeID;
    END
END;
GO
IF OBJECT_ID('edit_fine', 'P') IS NOT NULL
    DROP PROCEDURE edit_fine;
GO

CREATE PROCEDURE edit_fine
    @BookBorrowedID INT,
    @PaymentStatus NVARCHAR(50)
AS
BEGIN
    IF @PaymentStatus NOT IN (N'Paid', N'Unpaid')
    BEGIN
        RAISERROR(N'PaymentStatus must be either "Paid" or "Unpaid".', 16, 1);
        RETURN;
    END

    UPDATE LateReturnFine
    SET PaymentStatus = @PaymentStatus
    WHERE BookBorrowedID = @BookBorrowedID;
END;
GO
IF OBJECT_ID('member_login', 'P') IS NOT NULL
    DROP PROCEDURE member_login;
GO
CREATE PROCEDURE member_login
    @MemberID INT,
    @Password NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ActualPassword NVARCHAR(100);


    SELECT @ActualPassword = Password 
    FROM Member 
    WHERE MemberID = @MemberID;

    
    IF @ActualPassword IS NULL OR @ActualPassword <> @Password
    BEGIN
        RAISERROR(N'Invalid MemberID or Password.', 16, 1);
        RETURN;
    END

    SELECT * FROM Member WHERE MemberID = @MemberID;
END;
GO
IF OBJECT_ID('librarian_login', 'P') IS NOT NULL
    DROP PROCEDURE librarian_login;
GO
CREATE PROCEDURE librarian_login
    @EmployeeID INT,
    @Password NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ActualPassword NVARCHAR(100);

    SELECT @ActualPassword = Password 
    FROM Employee 
    WHERE EmployeeID = @EmployeeID;

    IF @ActualPassword IS NULL OR @ActualPassword <> @Password
    BEGIN
        RAISERROR(N'Invalid EmployeeID or Password.', 16, 1);
        RETURN;
    END

    SELECT * FROM Employee WHERE EmployeeID = @EmployeeID;
END;
GO
-- /*

-- Insert sample Writers
INSERT INTO Writer (WriterID, Name, LastName) VALUES (1, N'George', N'Orwell');
INSERT INTO Writer (WriterID, Name, LastName) VALUES (2, N'Jane', N'Austen');

-- Insert sample Books
INSERT INTO Book (BookID, Title, Publisher, PublishedYear, Translator, Genre) VALUES (1, N'1984', N'Secker & Warburg', 1949, NULL, N'Dystopian');
INSERT INTO Book (BookID, Title, Publisher, PublishedYear, Translator, Genre) VALUES (2, N'Pride and Prejudice', N'T. Egerton', 1813, NULL, N'Romance');

-- Insert sample Copies
INSERT INTO Copy (CopyID, BookID, State) VALUES (1, 1, N'Available');
INSERT INTO Copy (CopyID, BookID, State) VALUES (2, 1, N'Available');
INSERT INTO Copy (CopyID, BookID, State) VALUES (3, 2, N'Available');

-- Insert sample WriterBook
INSERT INTO WriterBook (WriterID, BookID) VALUES (1, 1);
INSERT INTO WriterBook (WriterID, BookID) VALUES (2, 2);
EXEC add_member  N'Test', N'Test', N'1234', N'Address', '2023-04-01', 5, N'Basic',N'09123456789';
EXEC add_member  N'Test2', N'Test2', N'1234', N'Address2', '2023-04-01', 5, N'VIP',N'09123456780';
INSERT INTO Employee (EmployeeID, Name, LastName, Password) VALUES (0, N'Admin', N'User', N'admin');
EXEC add_book  N'Emma', N'PublisherX', 2020, N'TranslatorX', N'Fiction';
EXEC add_book  N'Emma 2', N'PublisherX', 2020, N'TranslatorX', N'Fiction';
-- Insert sample Members
-- INSERT INTO Member (MemberID, Name, LastName, Password, Address, RegistrationDate, MaximumNumberOfBorrowedBooks, TypeOfMembership,PhoneNumber)
EXEC add_member  N'Alice', N'Smith', N'pass1', N'123 Main St', '2023-01-01', 3, N'Basic',N'09112223344';
--INSERT INTO Member (MemberID, Name, LastName, Password, Address, RegistrationDate, MaximumNumberOfBorrowedBooks, TypeOfMembership,PhoneNumber)
EXEC add_member N'Bob', N'Johnson', N'pass2', N'456 Oak Ave', '2023-02-01', 5, N'VIP',N'09123456788'

-- Insert sample PhoneNumbers
-- INSERT INTO PhoneNumbers (MemberID, PhoneNumber) VALUES (1, N'555-1234');
-- INSERT INTO PhoneNumbers (MemberID, PhoneNumber) VALUES (2, N'555-5678');

-- Insert sample Employees
-- INSERT INTO Employee (EmployeeID, Name, LastName, Password) VALUES (1, N'Emily', N'Brown', N'emp1');
-- INSERT INTO Employee (EmployeeID, Name, LastName, Password) VALUES (2, N'John', N'Doe', N'emp2');

-- Insert sample BookBorrowed
-- INSERT INTO BookBorrowed (BookBorrowedID, MemberID, CopyID, BorrowedDate, ReturnDate, PredictedReturnDate, ManagedByEmployeeID)
EXEC add_copy 1;
EXEC add_copy 1;



-- Insert sample LateReturnFine
-- INSERT INTO LateReturnFine (BookBorrowedID, FineAmount, PaymentStatus, ManagedByEmployeeID)
-- VALUES (1, 0.00, N'Unpaid', 1);

-- Insert sample Reservation
INSERT INTO Reservation (ReservationID, MemberID, BookID, ReserveDate)
VALUES (1, 2, 1, '2023-03-05');


-- Test SELECT * for all tables
SELECT * FROM Writer;
SELECT * FROM Book;
SELECT * FROM Copy;
SELECT * FROM WriterBook;
SELECT * FROM Member;
-- SELECT * FROM PhoneNumbers;
SELECT * FROM Employee;
SELECT * FROM BookBorrowed;
SELECT * FROM LateReturnFine;
SELECT * FROM Reservation;

-- Test SELECT * for all views
SELECT * FROM BookView;
SELECT * FROM MemberLoanView;
SELECT * FROM ReportFineView;
SELECT * FROM MemberFineView;
SELECT * FROM LibrarianLoanView;
SELECT * FROM LibrarianFineView;

-- Test procedures (example calls)

EXEC edit_member 3, N'Charlie', N'Lee', N'newpass', N'789 Pine Rd', 2, N'VIP',N'091111111111';
EXEC get_member 3;
EXEC search_member N'Charlie';
-- EXEC add_book 3, N'Emma', N'PublisherX', 2020, N'TranslatorX', N'Fiction';
-- EXEC edit_book 3, N'Emma Updated', N'PublisherX', 2021, N'TranslatorX', N'Fiction';
EXEC search_book N'Emma';
EXEC get_member_loans 1;
EXEC add_copy 2;
EXEC delete_copy 4;
EXEC get_member_fines 1;
EXEC get_librarian_loans 0;
EXEC get_librarian_fines 0;
EXEC register_loan 2, 2, 0, '2023-04-15';
SELECT * FROM BookBorrowed;
SELECT * FROM Copy;
EXEC register_loan 1, 1, 0, '2023-04-15';
EXEC edit_loan 1, '2023-04-20', 0;
EXEC register_loan 1, 1,0, '2025-08-15';
-- EXEC edit_fine 1, N'Paid';

-- Test SELECT * for all tables
SELECT * FROM Writer;
SELECT * FROM Book;
SELECT * FROM Copy;
SELECT * FROM WriterBook;
SELECT * FROM Member;
-- SELECT * FROM PhoneNumbers;
SELECT * FROM Employee;
SELECT * FROM BookBorrowed;
SELECT * FROM LateReturnFine;
SELECT * FROM Reservation;

-- Test SELECT * for all views
SELECT * FROM BookView;
SELECT * FROM MemberLoanView;
SELECT * FROM ReportFineView;
SELECT * FROM MemberFineView;
SELECT * FROM LibrarianLoanView;
SELECT * FROM LibrarianFineView;
EXEC get_member_loans 1;
EXEC get_member 1;
-- */

