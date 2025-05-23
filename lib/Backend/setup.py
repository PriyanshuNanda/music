from setuptools import setup, find_packages

setup(
    name="ytmusic_dl",
    version="1.0.0",
    packages=find_packages(),
    include_package_data=True,
    install_requires=[],  # No external requirements - all included in libs/
    entry_points={
        'console_scripts': [
            'ytmusic-dl=services.cli:main',
        ],
    },
    python_requires=">=3.6",
    author="YourName",
    description="YouTube Music Downloader with local dependencies",
    long_description=open("README.md").read(),
    long_description_content_type="text/markdown",
    package_data={
        'services': ['libs/**/*'],
    },
)
