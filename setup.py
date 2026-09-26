import setuptools
from pathlib import Path

ROOT = Path(__file__).resolve().parent
long_description = (ROOT / "README.md").read_text(encoding="utf-8")
requirements = [
    line.strip() for line in (ROOT / "requirements_modern.txt").read_text().splitlines()
    if line.strip() and not line.lstrip().startswith("#")
]

setuptools.setup(
    name="CKG", 
    version="2.0.0",
    author="Alberto Santos Delgado, Peter, Gemini",
    author_email="alberto.santos@sund.ku.dk",
    description="Clinical Knowledge Graph - Modernized for Python 3.10+ and Neo4j 5.x",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/treitpeter/CKG_development",
    packages=setuptools.find_packages(),
    install_requires=requirements,
    extras_require={"test": ["pytest>=8", "build>=1.2"]},
    entry_points={'console_scripts': [
        'ckg_app=ckg.report_manager.index:main',
        'ckg_debug=ckg.debug:main',
        'ckg_build=ckg.graphdb_builder.builder.builder:run_full_update',
        'ckg_update_textmining=ckg.graphdb_builder.builder.builder:update_textmining']},
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
    python_requires='>=3.10',
    include_package_data=True,
)
