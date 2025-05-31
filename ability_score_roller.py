import random
import argparse

def strikethrough(number):
    # Apply strikethrough to a number by adding U+0336 to each digit
    return ''.join(c + '\u0336' for c in str(number))

def roll_dice_drop_lowest(num_dice, sides, drop_lowest):
    # Ensure enough dice remain after dropping
    if num_dice - drop_lowest < 1:
        raise ValueError("Not enough dice remain after dropping lowest.")
    # Roll num_dice with specified sides
    rolls = [random.randint(1, sides) for _ in range(num_dice)]
    # Sort rolls in descending order
    rolls.sort(reverse=True)
    # Split into kept and dropped rolls
    kept_rolls = rolls[:num_dice - drop_lowest]
    dropped_rolls = rolls[num_dice - drop_lowest:]
    # Sum kept rolls
    score = sum(kept_rolls)
    # Format rolls for output: kept rolls as-is, dropped with strikethrough
    formatted_rolls = [str(r) for r in kept_rolls] + [strikethrough(r) for r in dropped_rolls]
    return score, rolls, formatted_rolls

def generate_ability_scores(num_dice, sides, drop_lowest, num_scores=6):
    # Generate specified number of ability scores with rolls
    results = [roll_dice_drop_lowest(num_dice, sides, drop_lowest) for _ in range(num_scores)]
    return results

def main():
    # Set up argument parser
    parser = argparse.ArgumentParser(description="Roll dice for ability scores, summing remaining rolls after dropping lowest.")
    parser.add_argument("--num_dice", type=int, default=4, help="Number of dice to roll (default: 4)")
    parser.add_argument("--sides", type=int, default=6, help="Number of sides per die (default: 6)")
    parser.add_argument("--drop_lowest", type=int, default=None, help="Number of lowest rolls to drop (default: num_dice - 3)")
    parser.add_argument("--debug", action="store_true", help="Print configuration before rolling (default: False)")

    # Parse arguments
    args = parser.parse_args()

    # Calculate drop_lowest: use command-line value if provided, else num_dice - 3
    drop_lowest = args.drop_lowest if args.drop_lowest is not None else args.num_dice - 3

    # Validate num_dice
    if args.num_dice < 1:
        raise ValueError("Number of dice must be at least 1.")

    # Print debug information if --debug is provided
    if args.debug:
        print("Configuration:")
        print(f"  Number of dice: {args.num_dice}")
        print(f"  Sides per die: {args.sides}")
        print(f"  Drop lowest: {drop_lowest}")
        print(f"  Dice to keep: {args.num_dice - drop_lowest}")
        print(f"  Scores to generate: 6")

    try:
        # Generate ability scores
        results = generate_ability_scores(args.num_dice, args.sides, drop_lowest)
        # Print results with rolls
        for i, (score, raw_rolls, formatted_rolls) in enumerate(results, 1):
            print(f"Ability Score {i}: {score:2d} ({' '.join(formatted_rolls)})")
    except ValueError as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()