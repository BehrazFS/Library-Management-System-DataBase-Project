import pyodbc
from debug import debug
class DataBase:
    def __init__(self):
        self.conn = None
        self.cursor = None

    def connect(self):
        try:
            self.conn = pyodbc.connect(
                "DRIVER={ODBC Driver 17 for SQL Server};"
                "SERVER=localhost,1433;"
                "DATABASE=LibraryManagementDB;"
                "UID=sa;"
                "PWD=Str0ngPassw0rd!;"
                "TrustServerCertificate=yes;"
                "Encrypt=no;"
            )
            self.cursor = self.conn.cursor()
            self.cursor.execute("SELECT @@VERSION")
            if debug: print("Connected! Version:", self.cursor.fetchone()[0])
        except Exception as e:
            if debug: print("Connection failed:", e)
            self.conn = None
            self.cursor = None

    def close(self):
        if self.cursor:
            self.cursor.close()
        if self.conn:
            self.conn.close()
        if debug: print("Database connection closed.")

    def member_login(self,username, password):
        try:
            self.cursor.execute("EXEC  member_login ?, ?;",(int(username), password))
            user = self.cursor.fetchall()
            if debug: print(user)
            return True, user , ""
        except Exception as e:
            if debug: print("error : " ,e)
            return False , None , "Invalid member credentials"
    def librarian_login(self,username, password):
        try:
            self.cursor.execute("EXEC  librarian_login ?, ?;",(int(username), password))
            user = self.cursor.fetchall()
            if debug: print(user)
            return True, user , ""
        except Exception as e:
            if debug: print("error : " ,e)
            return False , None , "Invalid librarian credentials"
    def search_book(self,keyword):
        try:
            self.cursor.execute("EXEC  search_book ?;",(keyword))
            books = self.cursor.fetchall()
            return books
        except Exception as e:
            if debug: print("error : " ,e)
            return None
    def get_member_loans(self,username):
        try:
            self.cursor.execute("EXEC get_member_loans ?;",(int(username)))
            list_of_loans = self.cursor.fetchall()
            if debug: print(list_of_loans)
            return list_of_loans
        except Exception as e:
            if debug: print("error : " ,e)
            return None
    def get_member_fines(self,username):
        try:
            self.cursor.execute("EXEC get_member_fines ?;",(int(username)))
            list_of_fines = self.cursor.fetchall()
            if debug: print(list_of_fines)
            return list_of_fines
        except Exception as e:
            if debug: print("error : " ,e)
            return None
    def search_member(self,keyword):
        try:
            self.cursor.execute("EXEC  search_member ?;",(keyword))
            members = self.cursor.fetchall()
            return members
        except Exception as e:
            if debug: print("error : " ,e)
            return None
    def get_fine_report(self,username):
        try:
            self.cursor.execute("EXEC get_report_fines ?;",(int(username)))
            fine_report = self.cursor.fetchall()
            if debug: print(fine_report)
            return fine_report
        except Exception as e:
            if debug: print("error : " ,e)
            return None
    def get_librarian_fines(self,username):
        try:
            self.cursor.execute("EXEC get_librarian_fines ?;",(int(username)))
            list_of_fines = self.cursor.fetchall()
            if debug: print(list_of_fines)
            return list_of_fines
        except Exception as e:
            if debug: print("error : " ,e)
            return None
    def get_loan_report(self,username):
        try:
            self.cursor.execute("EXEC get_report_loans ?;",(int(username)))
            loan_report = self.cursor.fetchall()
            if debug: print(loan_report)
            return loan_report
        except Exception as e:
            if debug: print("error : " ,e)
            return None
    def get_librarian_loans(self,username):
        try:
            self.cursor.execute("EXEC get_librarian_loans ?;",(int(username)))
            list_of_loans = self.cursor.fetchall()
            if debug: print(list_of_loans)
            return list_of_loans
        except Exception as e:
            if debug: print("error : " ,e)
            return None
    def add_member(self,*args):
        try:
            self.cursor.execute("EXEC add_member ?, ?, ?, ?, ?, ?, ?, ?;",args)
            self.conn.commit()
            return True , "Member added successfully"
        except Exception as e:
            if debug: print("error : " ,e)
            return False , "Failed to add member" 
    def edit_member(self,*args):
        try:
            self.cursor.execute("EXEC edit_member ?, ?, ?, ?, ?, ?, ?, ?;",args)
            self.conn.commit()
            if debug: print("edit done")
            return True , "Member edited successfully"
        except Exception as e:
            if debug: print("error : " ,e)
            return False , "Failed to edit member" 
    def get_member(self,id):
        try:
            self.cursor.execute("EXEC get_member ?;",(id))
            member = self.cursor.fetchall()
            if debug: print(member)
            return member
        except Exception as e:
            if debug: print("error : " ,e)
            return None 
    def delete_member(self,id):
        try:
            self.cursor.execute("EXEC delete_member ?;",(id))
            self.conn.commit()
            return True , "Member deleted successfully"
        except Exception as e:
            if debug: print("error : " ,e)
            return False , "Failed to delete member" 
    def add_book(self,*args):
        try:
            self.cursor.execute("EXEC add_book ?, ?, ?, ?, ?;",args)
            self.conn.commit()
            return True , "Book added successfully"
        except Exception as e:
            if debug: print("error : " ,e)
            return False , "Failed to add book" 
    def edit_book(self,*args):
        try:
            self.cursor.execute("EXEC edit_book ?, ?, ?, ?, ?, ?;",args)
            self.conn.commit()
            return True , "Book edited successfully"
        except Exception as e:
            if debug: print("error : " ,e)
            return False , "Failed to edit book" 
    def delete_book(self,id):
        try:
            self.cursor.execute("EXEC delete_book ?;",(id))
            self.conn.commit()
            return True , "Book deleted successfully"
        except Exception as e:
            if debug: print("error : " ,e)
            return False , "Failed to delete book"
    def get_book(self,id):
        try:
            self.cursor.execute("EXEC  get_book ?;",(id))
            book = self.cursor.fetchall()
            return book
        except Exception as e:
            if debug: print("error : " ,e)
            return None
    def add_copy(self,book_id):
        try:
            self.cursor.execute("EXEC add_copy ?;",book_id)
            self.conn.commit()
            return True , "Copy added successfully"
        except Exception as e:
            if debug: print("error : " ,e)
            return False , "Failed to add copy"
    def delete_copy(self,id):
        try:
            self.cursor.execute("EXEC delete_copy ?;",(id))
            self.conn.commit()
            return True , "Copy deleted successfully"
        except Exception as e:
            if debug: print("error : " ,e)
            return False , "Failed to delete copy"
    def get_copies(self,book_id):
        try:
            self.cursor.execute("EXEC get_copies ?;",(book_id))
            copies = self.cursor.fetchall()
            return copies
        except Exception as e:
            if debug: print("error : " ,e)
            return None
    def edit_loan(self, *args):
        try:
            self.cursor.execute("EXEC edit_loan ?, ?, ?;", args)
            self.conn.commit()
            return True, "Loan edited successfully"
        except Exception as e:
            if debug: print("error : ", e)
            return False, "Failed to edit loan"
    def edit_fine(self, *args):
        try:
            self.cursor.execute("EXEC edit_fine ?, ?;", args)
            self.conn.commit()
            return True, "Fine edited successfully"
        except Exception as e:
            if debug: print("error : ", e)
            return False, "Failed to edit fine"
    def register_loan(self, *args):
        try:
            self.cursor.execute("EXEC register_loan ?, ?, ?, ?;", args)
            self.conn.commit()
            return True, "Loan registered successfully"
        except Exception as e:
            if debug: print("error : ", e)
            return False, "Failed to register loan"