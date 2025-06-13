from kivy.app import App
from kivy.uix.scrollview import ScrollView
from kivy.uix.screenmanager import Screen, ScreenManager
from kivy.properties import ListProperty, ObjectProperty, NumericProperty, ReferenceListProperty, StringProperty
from kivy.utils import rgba
from kivy.lang import Builder
from kivy.factory import Factory
from kivy.properties import ListProperty, ObjectProperty
from kivy.uix.dropdown import DropDown
from kivy.uix.button import Button
from kivy.uix.label import Label
from kivy.base import ExceptionHandler, ExceptionManager
from database import DataBase
from kivy.core.window import Window
import datetime
from debug import debug
Window.size = (1000, 800)
if debug: print(Window.size)
class MainScreenManager(ScreenManager):
    db = ObjectProperty(None)
    current_user = ObjectProperty(None)
    
class LoginScreen(Screen):
    librarian_username = ObjectProperty()
    librarian_password = ObjectProperty()
    member_username = ObjectProperty()
    member_password = ObjectProperty()
    librarian_error = ObjectProperty()
    member_error = ObjectProperty()
    def librarian_login(self,username, password):
        result , user , error = self.manager.db.librarian_login(username,password)
        if result:
            self.manager.current_user = user
            if debug : print(self.manager.current_user)
            self.manager.get_screen('librarian').load_fines()
            self.manager.get_screen('librarian').load_loans()
            self.manager.current = "librarian"
            self.librarian_username.text = ""
            self.librarian_password.text = ""
            self.member_username.text = ""
            self.member_password.text = ""
        else:
            self.librarian_error.text=error
    def member_login(self,username, password):
        # if debug: print(self.manager.screens)
        # if debug: print(self.manager.get_screen('member'))
        result , user , error = self.manager.db.member_login(username,password)
        if result:
            self.manager.current_user = user
            self.manager.get_screen('member').load_loans()
            self.manager.get_screen('member').load_fines()
            self.manager.current = "member"
            self.librarian_username.text = ""
            self.librarian_password.text = ""
            self.member_username.text = ""
            self.member_password.text = ""
        else:
            self.member_error.text=error
    

class MemberScreen(Screen):
    member_search_book_input = ObjectProperty()
    member_books_list = ObjectProperty()
    member_borrowed_list = ObjectProperty()
    member_fines_list = ObjectProperty()
    def load_loans(self):
        # if debug: print(self.manager.current_user)
        self.member_borrowed_list.data = [{
                    "loan_id" : "LoanID",
                    "book_title" : "Title",
                    "book_id" : "BookID",
                    "member_id" : "MemberID",
                    "copy_id" :"CopyID",
                    "borrowed_date" : "LoanDate",
                    "return_date" : "ReturnDate",
                    "predicted_return_date" : "Predicted Return Date",
                    "managed_by_employee_id" : "EmployeeID"
                }] + [{
                    "loan_id" : str(row[0]),
                    "book_title" : str(row[1]),
                    "book_id" : str(row[2]),
                    "member_id" :str(row[3]),
                    "copy_id" : str(row[4]),
                    "borrowed_date" :str(row[5]),
                    "return_date" :str(row[6]),
                    "predicted_return_date" : str(row[7]),
                    "managed_by_employee_id" : str(row[8])
                } for row in self.manager.db.get_member_loans(self.manager.current_user[0][0])]
    def load_fines(self):
        self.member_fines_list.data = [{
                    "member_id" : "MemberID",
                    "name" : "Name",
                    "last_name" : "LastName",
                    "loan_id" : "LoanID",
                    "fine_amount" : "FineAmount",
                    "payment_status" :"Status"
                }] + [{
                    "member_id" : str(row[0]),
                    "name" : str(row[1]),
                    "last_name" : str(row[2]),
                    "loan_id" : str(row[3]),
                    "fine_amount" :str(row[4]),
                    "payment_status" : str(row[5])
                } for row in self.manager.db.get_member_fines(self.manager.current_user[0][0])]                
    def search_book(self, keyword):
        list_of_books = self.manager.db.search_book(keyword)
        if debug: print(list_of_books)
        if list_of_books:
            self.member_books_list.data = [{
                    "book_id": "BookID",
                    "title": "Title",
                    "publisher": "Publisher",
                    "year": "Year",
                    "translator": "Translator",
                    "genre": "Genre",
                    'available': "Available"                
                }] + [{
                    "book_id": str(row[0]),
                    "title": str(row[1]),
                    "publisher": str(row[2]),
                    "year": str(row[3]),
                    "translator": str(row[4]),
                    "genre": str(row[5]),
                    'available': str(row[6])
                }
                for row in list_of_books
            ]
        else:
            self.member_books_list.data =  [{
                    "book_id": "BookID",
                    "title": "Title",
                    "publisher": "Publisher",
                    "year": "Year",
                    "translator": "Translator",
                    "genre": "Genre",
                    'available': "Available"                
                }] + [{
                    "book_id": "",
                    "title": "No results found.",
                    "publisher": "",
                    "year": "",
                    "translator": "",
                    "genre": "",
                    'available': ""
                }
            ]
class LibrarianScreen(Screen):
    librarian_search_book_input = ObjectProperty()
    librarian_books_list = ObjectProperty()
    librarian_members_list = ObjectProperty()
    librarian_search_member_input = ObjectProperty()
    librarian_fine_report = ObjectProperty()
    librarian_fines_list = ObjectProperty()
    librarian_loans_list = ObjectProperty()
    librarian_loan_report = ObjectProperty()
    add_member = ObjectProperty()
    edit_member = ObjectProperty()
    delete_member = ObjectProperty()
    add_book = ObjectProperty()
    edit_book = ObjectProperty()
    delete_book = ObjectProperty()
    add_copy = ObjectProperty()
    delete_copy = ObjectProperty()
    librarian_copy_list = ObjectProperty()
    librarian_search_copy_input = ObjectProperty()
    edit_loan = ObjectProperty()
    edit_fine = ObjectProperty()
    register_loan = ObjectProperty()

    def register_loan_func(self,member_id,book_id,predicted_return_date):
        predicted_return_date = datetime.date(*list(map(int,predicted_return_date.split('-'))))
        result, error = self.manager.db.register_loan(member_id,book_id,self.manager.current_user[0][0],predicted_return_date)
        self.register_loan.message11.text = error
        if result:
            self.register_loan.memberid11.text = ""
            self.register_loan.bookid11.text = ""
            self.register_loan.predicted_return_date11.text = ""
    def edit_fine_func(self,loan_id,payment_status):
        result, error = self.manager.db.edit_fine(loan_id,payment_status)
        self.edit_fine.message10.text = error
        if result:
            self.edit_fine.loanid10.text = ""
            self.edit_fine.status10.text = ""
    def edit_loan_func(self,loan_id,return_date):
        return_date = datetime.date(*list(map(int,return_date.split('-'))))
        result, error = self.manager.db.edit_loan(loan_id,return_date,self.manager.current_user[0][0])
        self.edit_loan.message9.text = error
        if result:
            self.edit_loan.loanid9.text = ""
            self.edit_loan.return_date9.text = ""
        
    def search_copies(self, book_id):
        list_of_copies = self.manager.db.get_copies(book_id)
        if debug: print(list_of_copies)
        if list_of_copies:
            self.librarian_copy_list.data = [{
                    "copy_id": "CopyID",
                    "state": "State"
                }] + [{
                    "copy_id": str(row[0]),
                    "state": str(row[1])
                } for row in list_of_copies]
        else:
            self.librarian_copy_list.data = [{
                    "copy_id": "CopyID",
                    "state": "State"
                }] + [{
                    "copy_id": "",
                    "state": "No copies found."
                }]
    def add_copy_func(self, book_id):
        if debug: print("Adding copy")
        result, error = self.manager.db.add_copy(book_id)
        self.add_copy.message7.text = error
        if result:
            self.add_copy.bookid7.text = ""
    def delete_copy_func(self, copy_id):
        if debug: print("Deleting copy")
        result, error = self.manager.db.delete_copy(copy_id)
        self.delete_copy.message8.text = error
        if result:
            self.delete_copy.copyid8.text = ""
    def delete_book_func(self, book_id):
        result, error = self.manager.db.delete_book(book_id)
        self.delete_book.message6.text = error
        if result:
            self.delete_book.bookid6.text = ""
    def edit_book_set(self,book_id):
        book = self.manager.db.get_book(book_id)
        if book:
            book = book[0]
            self.edit_book.title5.disabled = False
            self.edit_book.publisher5.disabled = False
            self.edit_book.pubyear5.disabled = False
            self.edit_book.translator5.disabled = False
            self.edit_book.genre5.disabled = False
            self.edit_book.submit5.disabled = False
            self.edit_book.title5.text = str(book[1])
            self.edit_book.publisher5.text = str(book[2])
            self.edit_book.pubyear5.text = str(book[3])
            self.edit_book.translator5.text = str(book[4])
            self.edit_book.genre5.text = str(book[5])
            
    def edit_book_func(self,book_id,title,publisher,publishedyear,translator,genre):
        if debug: print("editing")
        result, error = self.manager.db.edit_book( book_id,title,publisher,publishedyear,translator,genre)
        self.edit_book.message5.text = error
        if debug: print(result,error)
        if result:
            self.edit_book.title5.disabled = True
            self.edit_book.publisher5.disabled = True
            self.edit_book.pubyear5.disabled = True
            self.edit_book.translator5.disabled = True
            self.edit_book.genre5.disabled = True
            self.edit_book.submit5.disabled = True
            self.edit_book.bookid5.text = ""
            self.edit_book.title5.text =""
            self.edit_book.publisher5.text =""
            self.edit_book.pubyear5.text =""
            self.edit_book.translator5.text = ""
            self.edit_book.genre5.text = "" 

    def add_book_func(self,title,publisher,publishedyear,translator,genre):
        if debug: print(title,publisher,publishedyear,translator,genre)
        result, error = self.manager.db.add_book( title,publisher,publishedyear,translator,genre)
        self.add_book.message4.text = error
        if result:
            self.add_book.title4.text = ""
            self.add_book.publisher4.text = ""
            self.add_book.pubyear4.text = ""
            self.add_book.translator4.text = ""
            self.add_book.genre4.text = ""
    def delete_member_func(self, member_id):
        result, error = self.manager.db.delete_member(member_id)
        self.delete_member.message3.text = error
        if result:
            self.delete_member.memberid3.text = ""
    def edit_member_set(self,member_id):
        if debug: print(self.edit_member.memberid2.text)
        if debug: print(f"setting edit ({member_id})")
        member = self.manager.db.get_member(member_id)
        if debug: print(member)
        if member:
            member = member[0]
            self.edit_member.name2.disabled = False
            self.edit_member.lastname2.disabled = False
            self.edit_member.password2.disabled = False
            self.edit_member.address2.disabled = False
            self.edit_member.maxbooks2.disabled = False
            self.edit_member.memtype2.disabled = False
            self.edit_member.phone2.disabled = False
            self.edit_member.submit2.disabled = False
            self.edit_member.name2.text = str(member[1])
            self.edit_member.lastname2.text =str( member[2])
            self.edit_member.password2.text = str(member[3])
            self.edit_member.address2.text = str(member[4])
            self.edit_member.maxbooks2.text = str(member[6])
            self.edit_member.memtype2.text = str(member[7])
            self.edit_member.phone2.text = str(member[8])

    def edit_member_func(self,member_id,name,last_name,password, address, max_books, mem_type, phone):
        if debug: print("editing")
        result, error = self.manager.db.edit_member( member_id,name, last_name,password, address, max_books, mem_type, phone)
        self.edit_member.message2.text = error
        if debug: print(result,error)
        if result:
            self.edit_member.name2.disabled = True
            self.edit_member.lastname2.disabled = True
            self.edit_member.password2.disabled = True
            self.edit_member.address2.disabled = True
            self.edit_member.maxbooks2.disabled = True
            self.edit_member.memtype2.disabled = True
            self.edit_member.phone2.disabled = True
            self.edit_member.submit2.disabled =True
            self.edit_member.memberid2.text = ""
            self.edit_member.name2.text = ""
            self.edit_member.lastname2.text = ""
            self.edit_member.password2.text = ""
            self.edit_member.address2.text = ""
            self.edit_member.maxbooks2.text = ""
            self.edit_member.memtype2.text = ""
            self.edit_member.phone2.text = "" 

    def add_member_func(self, name, last_name,password, address, reg_date, max_books, mem_type, phone):
        reg_date = datetime.date(*list(map(int,self.add_member.registrationdate.text.split('-'))))
        result, error = self.manager.db.add_member( name, last_name,password, address, reg_date, max_books, mem_type, phone)
        self.add_member.message.text = error
        if result:
            self.add_member.name.text = ""
            self.add_member.lastname.text = ""
            self.add_member.password.text = ""
            self.add_member.address.text = ""
            self.add_member.registrationdate.text = ""
            self.add_member.maxbooks.text = ""
            self.add_member.memtype.text = ""
            self.add_member.phone.text = "" 
            
    def load_loans(self):
        if debug: print(self.manager.current_user)
        loan_report = self.manager.db.get_loan_report(self.manager.current_user[0][0])
        if loan_report:
            self.librarian_loan_report.text = f"TotalLoans : {loan_report[0][0]}      |      ActiveLoans : {loan_report[0][1]}"
        
        self.librarian_loans_list.data = [{
                    "loan_id" : "LoanID",
                    "book_title" : "Title",
                    "book_id" : "BookID",
                    "member_id" : "MemberID",
                    "copy_id" :"CopyID",
                    "borrowed_date" : "LoanDate",
                    "return_date" : "ReturnDate",
                    "predicted_return_date" : "Predicted Return Date",
                    "managed_by_employee_id" : "EmployeeID"
                }] + [{
                    "loan_id" : str(row[0]),
                    "book_title" : str(row[1]),
                    "book_id" : str(row[2]),
                    "member_id" :str(row[3]),
                    "copy_id" : str(row[4]),
                    "borrowed_date" :str(row[5]),
                    "return_date" :str(row[6]),
                    "predicted_return_date" : str(row[7]),
                    "managed_by_employee_id" : str(row[8])
                } for row in self.manager.db.get_librarian_loans(self.manager.current_user[0][0])]

    def load_fines(self):
        fine_report = self.manager.db.get_fine_report(self.manager.current_user[0][0])
        if fine_report:
            self.librarian_fine_report.text = f"TotalUnpaidFines : {fine_report[0][0]}      |      TotalPaidFines : {fine_report[0][1]}      |      UnpaidFineCount : {fine_report[0][2]}      |       PaidFineCount : {fine_report[0][3]}"
        self.librarian_fines_list.data = [{
                    "member_id" : "MemberID",
                    "name" : "Name",
                    "last_name" : "LastName",
                    "loan_id" : "LoanID",
                    "fine_amount" : "FineAmount",
                    "payment_status" :"Status"
                }] + [{
                    "member_id" : str(row[0]),
                    "name" : str(row[1]),
                    "last_name" : str(row[2]),
                    "loan_id" : str(row[3]),
                    "fine_amount" :str(row[4]),
                    "payment_status" : str(row[5])
                } for row in self.manager.db.get_librarian_fines(self.manager.current_user[0][0])]
    def search_member(self,keyword):
        list_of_members = self.manager.db.search_member(keyword)
        if debug: print(list_of_members)
        if list_of_members:
            self.librarian_members_list.data = [{
                    "member_id":"MemberID",
                    "name":"Name",
                    "last_name":"LastName",
                    "address":"Address",
                    "reg_date" :"RegistrationDate",
                    "max_books" :"MaxBooks",
                    "mem_type" :"Type",
                    "phone":"Phone"             
                }] + [{
                    "member_id": str(row[0]),
                    "name": str(row[1]),
                    "last_name": str(row[2]),
                    "address": str(row[3]),
                    "reg_date": str(row[4]),
                    "max_books": str(row[5]),
                    'mem_type': str(row[6]),
                    "phone": str(row[7])
                }
                for row in list_of_members
            ]
        else:
            self.librarian_books_list.data =  [{
                    "book_id": "BookID",
                    "title": "Title",
                    "publisher": "Publisher",
                    "year": "Year",
                    "translator": "Translator",
                    "genre": "Genre",
                    'available': "Available"                
                }] + [{
                    "book_id": "",
                    "title": "No results found.",
                    "publisher": "",
                    "year": "",
                    "translator": "",
                    "genre": "",
                    'available': ""
                }
            ]
    def search_book(self, keyword):
        list_of_books = self.manager.db.search_book(keyword)
        if debug: print(list_of_books)
        if list_of_books:
            self.librarian_books_list.data = [{
                    "book_id": "BookID",
                    "title": "Title",
                    "publisher": "Publisher",
                    "year": "Year",
                    "translator": "Translator",
                    "genre": "Genre",
                    'available': "Available"                
                }] + [{
                    "book_id": str(row[0]),
                    "title": str(row[1]),
                    "publisher": str(row[2]),
                    "year": str(row[3]),
                    "translator": str(row[4]),
                    "genre": str(row[5]),
                    'available': str(row[6])
                }
                for row in list_of_books
            ]
        else:
            self.librarian_books_list.data =  [{
                    "book_id": "BookID",
                    "title": "Title",
                    "publisher": "Publisher",
                    "year": "Year",
                    "translator": "Translator",
                    "genre": "Genre",
                    'available': "Available"                
                }] + [{
                    "book_id": "",
                    "title": "No results found.",
                    "publisher": "",
                    "year": "",
                    "translator": "",
                    "genre": "",
                    'available': ""
                }
            ]

KV = Builder.load_file("library.kv")

class MyLibraryApp(App):
    def build(self):
        root = KV
        ids = root.ids
        root.db = DataBase()
        try:
            root.db.connect()
            if root.db.conn:
                if debug: print("Database connection setup complete.")
            else:
                if debug: print("Database connection failed.")
        except Exception as e:
            if debug: print(f"An error occurred while connecting to the database: {e}")
        
        return root
class Handler(ExceptionHandler):
    def handle_exception(self, inst):
        if debug: print(str(inst))
        return ExceptionManager.PASS

if __name__ == "__main__":
    ExceptionManager.add_handler(Handler())
    MyLibraryApp().run()