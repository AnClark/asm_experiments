get_avg = lambda A,B,C : (4*A + 2*B + C) / 7

if __name__ == "__main__":
    A = int(input("A = "))
    B = int(input("B = "))
    C = int(input("C = "))
    print("Average mark is: %d" % get_avg(A, B, C))
    
