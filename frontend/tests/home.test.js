import { render, screen, waitFor } from '@testing-library/react'
import Home from '../pages/index'

// Mock axios
jest.mock('axios')
const axios = require('axios')

describe('Home Page', () => {
  beforeEach(() => {
    axios.get.mockClear()
  })

  test('renders loading state initially', () => {
    render(<Home />)
    expect(screen.getByText('Loading...')).toBeInTheDocument()
  })

  test('renders success message when backend is connected', async () => {
    // Mock successful API responses
    axios.get.mockResolvedValueOnce({ 
      data: { status: 'healthy', message: 'Backend is running successfully' } 
    })
    axios.get.mockResolvedValueOnce({ 
      data: { message: 'You\'ve successfully integrated the backend!' } 
    })

    render(<Home />)
    
    await waitFor(() => {
      expect(screen.getByText('Backend is connected!')).toBeInTheDocument()
    })
    
    expect(screen.getByText('You\'ve successfully integrated the backend!')).toBeInTheDocument()
  })
})
