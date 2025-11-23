using System;
using System.Collections.Generic;

namespace SimpleBank
{
    class Account
    {
        public string AccountNumber { get; set; }
        public string Owner { get; set; }
        public decimal Balance { get; private set; }

        public Account(string accountNumber, string owner, decimal initialBalance = 0)
        {
            AccountNumber = accountNumber;
            Owner = owner;
            Balance = initialBalance;
        }

        public void Deposit(decimal amount)
        {
            if (amount > 0)
            {
                Balance += amount;
                Console.WriteLine($"Deposited {amount:C}. New balance: {Balance:C}");
            }
            else
            {
                Console.WriteLine("Invalid deposit amount.");
            }
        }

        public void Withdraw(decimal amount)
        {
            if (amount > 0 && amount <= Balance)
            {
                Balance -= amount;
                Console.WriteLine($"Withdrew {amount:C}. New balance: {Balance:C}");
            }
            else
            {
                Console.WriteLine("Insufficient funds or invalid withdrawal amount.");
            }
        }

        public void CheckBalance()
        {
            Console.WriteLine($"Account {AccountNumber} - Owner: {Owner} - Balance: {Balance:C}");
        }
    }

    class Bank
    {
        private List<Account> accounts = new List<Account>();

        public void CreateAccount(string accountNumber, string owner, decimal initialBalance = 0)
        {
            accounts.Add(new Account(accountNumber, owner, initialBalance));
            Console.WriteLine($"Account {accountNumber} created for {owner}.");
        }

        public Account GetAccount(string accountNumber)
        {
            return accounts.Find(a => a.AccountNumber == accountNumber);
        }
    }

    class Program
    {
        static void Main(string[] args)
        {
            Bank bank = new Bank();

            // Example usage
            bank.CreateAccount("12345", "John Doe", 1000);
            var account = bank.GetAccount("12345");
            if (account != null)
            {
                account.CheckBalance();
                account.Deposit(500);
                account.Withdraw(200);
                account.CheckBalance();
            }
            else
            {
                Console.WriteLine("Account not found.");
            }
        }
    }
}
