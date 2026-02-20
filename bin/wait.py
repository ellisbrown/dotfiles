import time
import argparse
from tqdm import tqdm

parser = argparse.ArgumentParser(description='Delay for a given time')
parser.add_argument('-H', '--hours', type=int, default=0, help='hours')
parser.add_argument('-M', '--minutes', type=int, default=0, help='minutes')
parser.add_argument('-S', '--seconds', type=int, default=0, help='seconds')
args = parser.parse_args()


def wait(hours: int, minutes: int, seconds: int) -> None:
    total = hours * 3600 + minutes * 60 + seconds
    for i in tqdm(range(total), desc="Waiting", unit="s"):
        time.sleep(1)
    print("Done!")


if __name__ == "__main__":
    wait(args.hours, args.minutes, args.seconds)