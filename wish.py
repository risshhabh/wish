from sys import argv


def relpath(cpp_file, src_dir) -> None:
    # Get relpath of cpp_file
    # sys.argv[2] == cpp_file
    # sys.argv[3] == src_dir

    # wish is intended for non-Windows
    from pathlib import PurePosixPath

    relpath = PurePosixPath(cpp_file).relative_to(src_dir)
    print(str(relpath))  # ./path/to/file.cpp


def remove_ext(file_path) -> None:
    from os import path

    print(path.splitext(path.basename(file_path))[0])


if argv[1] == "1":
    relpath(argv[2], argv[3])
elif argv[1] == "2":
    remove_ext(argv[2])
