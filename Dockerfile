# See https://aka.ms/containerfastmode to understand how Visual Studio uses this Dockerfile to build your images for faster debugging.

# Set the base image to the ASP.NET runtime on .NET 6.0
FROM mcr.microsoft.com/dotnet/aspnet:6.0 AS base

# Add PowerShell to the container
RUN apt-get update
RUN apt-get install -y wget apt-transport-https software-properties-common git
RUN wget -q https://packages.microsoft.com/config/ubuntu/22.10/packages-microsoft-prod.deb
RUN wget -q https://github.com/PowerShell/PowerShell/releases/download/v7.3.2/powershell_7.3.2-1.deb_amd64.deb
RUN dpkg -i powershell_7.3.2-1.deb_amd64.deb
RUN apt-get install -f

# Clone the ARM_TTK repository
WORKDIR /app
RUN git clone https://github.com/Azure/arm-ttk.git 
RUN chmod +x /app/arm-ttk/arm-ttk/Test-AzTemplate.sh

# Expose ports 80 and 443
EXPOSE 80
EXPOSE 443

# Set the image used for building the container to the .NET SDK on .NET 6.0
FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build

# Set the working directory to /src and copy the project file
WORKDIR /src
COPY ["ArmValidation.csproj", "."]

# Restore NuGet packages
RUN dotnet restore "./ArmValidation.csproj"

# Copy the remaining source code
COPY . .

# Change the working directory to /src/ and build the project
WORKDIR "/src/."
RUN dotnet build "ArmValidation.csproj" -c Release -o /app/build

# Set the image used for running the container to the base image
FROM base AS final

# Set the working directory to /app and copy the published files from the build image
WORKDIR /app
COPY --from=publish /app/publish .

# Set the entry point for the container to the application
ENTRYPOINT ["dotnet", "ArmValidation.dll"]
