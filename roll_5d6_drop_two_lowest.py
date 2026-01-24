import random

def roll_5d6_drop_two_lowest():
    # Roll 5 six-sided dice
    rolls = [random.randint(1, 6) for _ in range(5)]
    print(f"Rolls: {rolls}")
    
    # Sort the rolls in ascending order
    sorted_rolls = sorted(rolls)
    #print(f"Sorted rolls: {sorted_rolls}")
    
    # The two lowest are the first two in the sorted list
    dropped = sorted_rolls[:2]
    kept = sorted_rolls[2:]
    #print(f"Dropped: {dropped}")
    print(f"Kept: {kept}")
    
    # Sum the remaining three
    total = sum(kept)
    print(f"Total: {total}\n")
    return total

# Repeat the process 6 times
for _ in range(6):
    roll_5d6_drop_two_lowest()
