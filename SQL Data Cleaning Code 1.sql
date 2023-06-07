-- SQL DATA CLEANING - Nashville Housing Data --


-- SELECT * --

SELECT *
FROM ProjectPortfolio1..NashvilleHousing


-- STANDARDISE DATE FORMAT --


SELECT SaleDateConverted, CONVERT(Date, SaleDate)
FROM ProjectPortfolio1..NashvilleHousing

UPDATE NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate)

ALTER Table NashvilleHousing
Add SaleDateConverted Date;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)


-- POPULATE PROPERTY ADDRESS DATA -- 


SELECT *
FROM ProjectPortfolio1..NashvilleHousing
WHERE PropertyAddress IS NULL
ORDER BY ParcelID


-- Using self join to populate ParcelID with null addresses --

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM ProjectPortfolio1..NashvilleHousing a 
JOIN ProjectPortfolio1..NashvilleHousing b   
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ] 
WHERE a.PropertyAddress IS NULL    

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM ProjectPortfolio1..NashvilleHousing a
JOIN ProjectPortfolio1..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]


-- SPLITTING ADDRESS INTO SEPARATE FIELDS ( ADDRESS, CITY, STATE) -- SUBSTRING -- CHARACTER INDEX --

--Mehtod 1 (Substring) --


SELECT PropertyAddress
FROM ProjectPortfolio1..NashvilleHousing


SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)) AS Address 
FROM ProjectPortfolio1..NashvilleHousing


SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)) AS Address, CHARINDEX(',', PropertyAddress) AS PositionOfString
FROM ProjectPortfolio1..NashvilleHousing


SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address
FROM ProjectPortfolio1..NashvilleHousing


SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address, -- same as previous
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS Address
FROM ProjectPortfolio1..NashvilleHousing


ALTER Table NashvilleHousing
Add ProperySplitAddress Nvarchar(255); -- creating the column for split address

UPDATE NashvilleHousing
SET ProperySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) -- updating the column with the 1st SUBSTRING

ALTER Table NashvilleHousing
Add PropertySplitCity Nvarchar(255); -- creating column for split city

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) -- updating the column with the 2nd SUBSTRING

SELECT * 
FROM ProjectPortfolio1..NashvilleHousing


-- Method 2 (Parse Name) --


SELECT 
PARSENAME(OwnerAddress, 1)
FROM ProjectPortfolio1..NashvilleHousing


SELECT 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM ProjectPortfolio1..NashvilleHousing

SELECT 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS Address,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS City, 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) As State
FROM ProjectPortfolio1..NashvilleHousing

ALTER Table NashvilleHousing
Add OwnerSplitAddress Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) 

ALTER Table NashvilleHousing
Add OwnerSplitCity Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER Table NashvilleHousing
Add OwnerSplitState Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

SELECT * 
FROM ProjectPortfolio1..NashvilleHousing


-- Changing Y/N to Yes/No in SoldAsVacant -- CASE Statements --


SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant) 
FROM ProjectPortfolio1..NashvilleHousing
GROUP BY SoldAsVacant
Order by 2

SELECT SoldAsVacant,
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'NO'
		 ELSE SoldAsVacant
		 END
FROM ProjectPortfolio1..NashvilleHousing


UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes' 
		 WHEN SoldAsVacant = 'N' THEN 'NO'
		 ELSE SoldAsVacant
		 END


-- Removing Duplicates -- 


SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
	ORDER BY UniqueID) row_num 
FROM ProjectPortfolio1..NashvilleHousing
ORDER BY ParcelID

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
	ORDER BY UniqueID) row_num 
FROM ProjectPortfolio1..NashvilleHousing
)

SELECT *
FROM RowNumCTE
WHERE row_num > 1 


WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference 
	ORDER BY UniqueID) row_num 
FROM ProjectPortfolio1..NashvilleHousing
)

DELETE
FROM RowNumCTE
WHERE row_num > 1


-- Deleting Unused Columns --

SELECT *
FROM ProjectPortfolio1..NashvilleHousing

ALTER TABLE ProjectPortfolio1..NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

ALTER TABLE ProjectPortfolio1..NashvilleHousing
DROP COLUMN SaleDate