import importlib
import geneseq
importlib.reload(geneseq)
from geneseq import TripletSequenceGenerator

# Example usage:

predefined_sequence = [3, 1, 0, 2]
generator = TripletSequenceGenerator(predefined_sequence, display_info=True)
generator.generate(100)
final_sequence = generator.final_sequence

# Apply the cw90 mapping rule to the final sequence
cw90_sequence = generator.cw90(final_sequence)
print("\nCW90 Mapped Sequence:")
print(cw90_sequence)
